package dev.appu.bmsremote.ble

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.BluetoothStatusCodes
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.ParcelUuid
import androidx.core.content.ContextCompat
import androidx.core.content.IntentCompat
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withTimeoutOrNull

/** A BMS Tool seen while scanning. */
data class FoundDevice(val device: BluetoothDevice, val name: String, val rssi: Int) {
    val address: String get() = device.address
}

sealed interface ConnectionState {
    data object Disconnected : ConnectionState
    data object Scanning : ConnectionState
    /** More than one BMS Tool is nearby; waiting for the user to pick one. Scanning continues. */
    data class Choosing(val devices: List<FoundDevice>) : ConnectionState
    data class Connecting(val name: String) : ConnectionState
    data class Pairing(val name: String) : ConnectionState
    data class Connected(val name: String) : ConnectionState
    data class Failed(val message: String) : ConnectionState
}

class BleException(message: String) : Exception(message)

/**
 * Talks to the ESP32: scans for its service UUID, connects, pairs with the
 * passkey, subscribes to status notifications and writes commands.
 * The UI makes sure Bluetooth permissions are granted before calling [connect].
 */
@SuppressLint("MissingPermission")
class BmsBleClient(context: Context, private val scope: CoroutineScope) {

    private val appContext = context.applicationContext
    private val adapter: BluetoothAdapter? =
        appContext.getSystemService(BluetoothManager::class.java)?.adapter

    private val _connection = MutableStateFlow<ConnectionState>(ConnectionState.Disconnected)
    val connection: StateFlow<ConnectionState> = _connection.asStateFlow()

    private val _status = MutableStateFlow<BmsStatus?>(null)
    val status: StateFlow<BmsStatus?> = _status.asStateFlow()

    private val _errors = MutableSharedFlow<String>(extraBufferCapacity = 4)
    val errors: SharedFlow<String> = _errors.asSharedFlow()

    val isBluetoothEnabled: Boolean get() = adapter?.isEnabled == true

    private var gatt: BluetoothGatt? = null
    private var commandChar: BluetoothGattCharacteristic? = null
    private var connectJob: Job? = null

    // One GATT operation runs at a time; the callbacks below complete these.
    private val gattMutex = Mutex()
    @Volatile private var connected = CompletableDeferred<Unit>()
    @Volatile private var servicesDiscovered = CompletableDeferred<Int>()
    @Volatile private var pendingWrite: CompletableDeferred<Int>? = null
    @Volatile private var pendingRead: CompletableDeferred<ByteArray?>? = null
    @Volatile private var pendingChoice: CompletableDeferred<String>? = null
    @Volatile private var mtuChanged = CompletableDeferred<Int>()
    @Volatile private var mtu = DEFAULT_MTU

    private val _canMonitorSupported = MutableStateFlow(false)
    /** True when the connected firmware can forward raw CAN frames. */
    val canMonitorSupported: StateFlow<Boolean> = _canMonitorSupported.asStateFlow()

    /** Called on a Bluetooth thread with each batch of raw CAN frames. */
    @Volatile var rawListener: ((List<CanFrame>) -> Unit)? = null
    private val decoder = CanPacketDecoder()

    fun connect() {
        if (connectJob?.isActive == true) return
        val bt = adapter
        if (bt == null) {
            _connection.value = ConnectionState.Failed("This phone has no Bluetooth LE")
            return
        }
        connectJob = scope.launch {
            try {
                _connection.value = ConnectionState.Scanning
                val found = findDevice(bt)
                setUp(found.device, found.name)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                closeGatt()
                _connection.value = ConnectionState.Failed(e.message ?: "Connection failed")
            }
        }
    }

    fun disconnect() {
        connectJob?.cancel()
        connectJob = null
        closeGatt()
        _status.value = null
        _connection.value = ConnectionState.Disconnected
    }

    /** Picks a device from [ConnectionState.Choosing]. */
    fun choose(address: String) {
        pendingChoice?.complete(address)
    }

    fun send(command: BmsCommand) = sendBytes(byteArrayOf(command.code))

    private fun sendBytes(bytes: ByteArray) {
        scope.launch {
            try {
                val g = gatt ?: throw BleException("Not connected")
                val c = commandChar ?: throw BleException("Not connected")
                write(g, c, bytes)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                _errors.tryEmit(e.message ?: "Command failed")
            }
        }
    }

    private data class ScanState(
        val devices: Map<String, FoundDevice> = emptyMap(),  // insertion order = order found
        val error: Int? = null,
    )

    /**
     * Scans for BMS Tools. If only one shows up it is returned straight away; if
     * several do, they are offered as [ConnectionState.Choosing] (kept up to date
     * while scanning continues) and this waits for [choose].
     */
    private suspend fun findDevice(bt: BluetoothAdapter): FoundDevice = coroutineScope {
        val scanner = bt.bluetoothLeScanner ?: throw BleException("Bluetooth is off")
        val scan = MutableStateFlow(ScanState())
        val callback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                val name = result.scanRecord?.deviceName ?: result.device.name ?: "BMS Tool"
                val found = FoundDevice(result.device, name, result.rssi)
                scan.update { it.copy(devices = it.devices + (found.address to found)) }
            }

            override fun onScanFailed(errorCode: Int) {
                scan.update { it.copy(error = errorCode) }
            }
        }
        val filters = listOf(
            ScanFilter.Builder().setServiceUuid(ParcelUuid(BmsProtocol.SERVICE_UUID)).build()
        )
        val settings = ScanSettings.Builder().setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY).build()
        scanner.startScan(filters, settings, callback)
        try {
            val first = withTimeoutOrNull(SCAN_TIMEOUT_MS) {
                scan.first { it.devices.isNotEmpty() || it.error != null }
            } ?: throw BleException("No BMS Tool found. Is the ESP32 powered and nearby?")
            first.error?.let { throw BleException("Scan failed (error $it)") }

            delay(SETTLE_MS)  // give any other tools nearby a moment to show up
            val devices = scan.value.devices
            if (devices.size == 1) return@coroutineScope devices.values.first()

            val choice = CompletableDeferred<String>().also { pendingChoice = it }
            val mirror = launch {
                scan.collect { _connection.value = ConnectionState.Choosing(it.devices.values.toList()) }
            }
            val address = choice.await()
            mirror.cancel()
            scan.value.devices.getValue(address)
        } finally {
            pendingChoice = null
            runCatching { scanner.stopScan(callback) }
        }
    }

    private suspend fun setUp(device: BluetoothDevice, name: String) {
        _connection.value = ConnectionState.Connecting(name)
        connected = CompletableDeferred()
        servicesDiscovered = CompletableDeferred()
        gatt = device.connectGatt(appContext, false, gattCallback, BluetoothDevice.TRANSPORT_LE)
            ?: throw BleException("Could not connect")
        withTimeoutOrNull(CONNECT_TIMEOUT_MS) { connected.await() }
            ?: throw BleException("The BMS Tool did not answer")

        // The ESP32 only allows encrypted access, so pair (passkey) before touching the service.
        if (device.bondState != BluetoothDevice.BOND_BONDED) {
            _connection.value = ConnectionState.Pairing(name)
            awaitBond(device, name)
        }

        val g = gatt ?: throw BleException("Disconnected")
        // A bigger MTU lets the CAN monitor send 14 frames per notification instead of 1.
        mtuChanged = CompletableDeferred()
        mtu = if (g.requestMtu(REQUESTED_MTU)) {
            withTimeoutOrNull(OP_TIMEOUT_MS) { mtuChanged.await() } ?: DEFAULT_MTU
        } else {
            DEFAULT_MTU
        }
        if (!g.discoverServices()) throw BleException("Service discovery failed")
        val discovery = withTimeoutOrNull(OP_TIMEOUT_MS) { servicesDiscovered.await() }
            ?: throw BleException("Service discovery timed out")
        if (discovery != BluetoothGatt.GATT_SUCCESS) throw BleException(gattError(discovery))

        val service = g.getService(BmsProtocol.SERVICE_UUID)
            ?: throw BleException("This device is not a BMS Tool")
        val statusChar = service.getCharacteristic(BmsProtocol.STATUS_UUID)
            ?: throw BleException("BMS Tool firmware is out of date")
        commandChar = service.getCharacteristic(BmsProtocol.COMMAND_UUID)
            ?: throw BleException("BMS Tool firmware is out of date")

        g.setCharacteristicNotification(statusChar, true)
        val cccd = statusChar.getDescriptor(BmsProtocol.CCCD_UUID)
            ?: throw BleException("BMS Tool firmware is out of date")
        writeDescriptor(g, cccd, BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)

        // Older firmware has no CAN monitor characteristic; the rest still works.
        val rawChar = service.getCharacteristic(BmsProtocol.RAW_UUID)
        val rawCccd = rawChar?.getDescriptor(BmsProtocol.CCCD_UUID)
        if (rawChar != null && rawCccd != null) {
            g.setCharacteristicNotification(rawChar, true)
            writeDescriptor(g, rawCccd, BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)
            _canMonitorSupported.value = true
        }
        read(g, statusChar)?.let(BmsStatus::parse)?.let(::setStatus)

        _connection.value = ConnectionState.Connected(name)
    }

    /** Asks the ESP32 to forward every CAN frame; they arrive through [rawListener]. */
    fun startCanMonitor() {
        decoder.reset()
        gatt?.requestConnectionPriority(BluetoothGatt.CONNECTION_PRIORITY_HIGH)
        val payload = mtu - 3
        sendBytes(byteArrayOf(BmsCommand.StartRaw.code, (payload and 0xFF).toByte(), (payload shr 8).toByte()))
    }

    fun stopCanMonitor() {
        sendBytes(byteArrayOf(BmsCommand.StopRaw.code))
        gatt?.requestConnectionPriority(BluetoothGatt.CONNECTION_PRIORITY_BALANCED)
    }

    private suspend fun awaitBond(device: BluetoothDevice, name: String) {
        val result = CompletableDeferred<Boolean>()
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                val changed = IntentCompat.getParcelableExtra(
                    intent, BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java
                )
                if (changed?.address != device.address) return
                when (intent.getIntExtra(BluetoothDevice.EXTRA_BOND_STATE, BluetoothDevice.ERROR)) {
                    BluetoothDevice.BOND_BONDED -> result.complete(true)
                    BluetoothDevice.BOND_NONE -> result.complete(false)
                }
            }
        }
        ContextCompat.registerReceiver(
            appContext, receiver,
            IntentFilter(BluetoothDevice.ACTION_BOND_STATE_CHANGED),
            ContextCompat.RECEIVER_EXPORTED,
        )
        try {
            when (device.bondState) {
                BluetoothDevice.BOND_BONDED -> return
                BluetoothDevice.BOND_NONE ->
                    if (!device.createBond()) throw BleException("Pairing could not start")
            }
            val paired = withTimeoutOrNull(PAIR_TIMEOUT_MS) { result.await() }
                ?: throw BleException("Pairing timed out")
            if (!paired) throw BleException(
                "Pairing failed. Check the passkey, or remove \"$name\" in the phone's Bluetooth settings and try again."
            )
        } finally {
            appContext.unregisterReceiver(receiver)
        }
    }

    private suspend fun write(g: BluetoothGatt, c: BluetoothGattCharacteristic, value: ByteArray) =
        gattMutex.withLock {
            val done = CompletableDeferred<Int>().also { pendingWrite = it }
            val started = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                g.writeCharacteristic(c, value, BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT) ==
                    BluetoothStatusCodes.SUCCESS
            } else {
                legacyWrite(g, c, value)
            }
            if (!started) throw BleException("Bluetooth is busy, try again")
            val status = withTimeoutOrNull(OP_TIMEOUT_MS) { done.await() }
                ?: throw BleException("No answer from the BMS Tool")
            if (status != BluetoothGatt.GATT_SUCCESS) throw BleException(gattError(status))
        }

    private suspend fun writeDescriptor(g: BluetoothGatt, d: BluetoothGattDescriptor, value: ByteArray) =
        gattMutex.withLock {
            val done = CompletableDeferred<Int>().also { pendingWrite = it }
            val started = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                g.writeDescriptor(d, value) == BluetoothStatusCodes.SUCCESS
            } else {
                legacyWriteDescriptor(g, d, value)
            }
            if (!started) throw BleException("Bluetooth is busy, try again")
            val status = withTimeoutOrNull(OP_TIMEOUT_MS) { done.await() }
                ?: throw BleException("No answer from the BMS Tool")
            if (status != BluetoothGatt.GATT_SUCCESS) throw BleException(gattError(status))
        }

    private suspend fun read(g: BluetoothGatt, c: BluetoothGattCharacteristic): ByteArray? =
        gattMutex.withLock {
            val done = CompletableDeferred<ByteArray?>().also { pendingRead = it }
            if (!g.readCharacteristic(c)) throw BleException("Bluetooth is busy, try again")
            withTimeoutOrNull(OP_TIMEOUT_MS) { done.await() }
        }

    @Suppress("DEPRECATION")
    private fun legacyWrite(g: BluetoothGatt, c: BluetoothGattCharacteristic, value: ByteArray): Boolean {
        c.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
        c.value = value
        return g.writeCharacteristic(c)
    }

    @Suppress("DEPRECATION")
    private fun legacyWriteDescriptor(g: BluetoothGatt, d: BluetoothGattDescriptor, value: ByteArray): Boolean {
        d.value = value
        return g.writeDescriptor(d)
    }

    private fun onStatusBytes(value: ByteArray) {
        BmsStatus.parse(value)?.let(::setStatus)
    }

    private fun setStatus(status: BmsStatus) {
        decoder.protocolVersion = status.protocolVersion
        _status.value = status
    }

    private fun closeGatt() {
        gatt?.let {
            runCatching { it.disconnect() }
            runCatching { it.close() }
        }
        gatt = null
        commandChar = null
        _canMonitorSupported.value = false
    }

    private fun onCharacteristicValue(c: BluetoothGattCharacteristic, value: ByteArray) {
        when (c.uuid) {
            BmsProtocol.STATUS_UUID -> onStatusBytes(value)
            BmsProtocol.RAW_UUID -> rawListener?.invoke(decoder.decode(value))
        }
    }

    private fun gattError(status: Int): String = when (status) {
        GATT_INSUFFICIENT_AUTHENTICATION, GATT_INSUFFICIENT_ENCRYPTION ->
            "Not paired. Remove this BMS Tool in the phone's Bluetooth settings and connect again."
        else -> "Bluetooth error $status"
    }

    private val gattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(g: BluetoothGatt, status: Int, newState: Int) {
            if (newState == BluetoothProfile.STATE_CONNECTED && status == BluetoothGatt.GATT_SUCCESS) {
                connected.complete(Unit)
                return
            }
            if (newState != BluetoothProfile.STATE_DISCONNECTED) return

            val lost = BleException(
                if (status == BluetoothGatt.GATT_SUCCESS) "Disconnected" else "Could not connect (error $status)"
            )
            connected.completeExceptionally(lost)
            servicesDiscovered.completeExceptionally(lost)
            pendingWrite?.completeExceptionally(lost)
            pendingRead?.completeExceptionally(lost)
            if (_connection.value is ConnectionState.Connected) {
                closeGatt()
                _status.value = null
                _connection.value = ConnectionState.Failed("Connection to the BMS Tool was lost")
            }
        }

        override fun onMtuChanged(g: BluetoothGatt, mtu: Int, status: Int) {
            mtuChanged.complete(if (status == BluetoothGatt.GATT_SUCCESS) mtu else DEFAULT_MTU)
        }

        override fun onServicesDiscovered(g: BluetoothGatt, status: Int) {
            servicesDiscovered.complete(status)
        }

        override fun onCharacteristicWrite(g: BluetoothGatt, c: BluetoothGattCharacteristic, status: Int) {
            pendingWrite?.complete(status)
        }

        override fun onDescriptorWrite(g: BluetoothGatt, d: BluetoothGattDescriptor, status: Int) {
            pendingWrite?.complete(status)
        }

        override fun onCharacteristicRead(
            g: BluetoothGatt, c: BluetoothGattCharacteristic, value: ByteArray, status: Int,
        ) {
            pendingRead?.complete(if (status == BluetoothGatt.GATT_SUCCESS) value else null)
        }

        @Deprecated("Called on Android 12 and older")
        override fun onCharacteristicRead(g: BluetoothGatt, c: BluetoothGattCharacteristic, status: Int) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) return
            @Suppress("DEPRECATION")
            val value = c.value
            pendingRead?.complete(if (status == BluetoothGatt.GATT_SUCCESS) value else null)
        }

        override fun onCharacteristicChanged(g: BluetoothGatt, c: BluetoothGattCharacteristic, value: ByteArray) {
            onCharacteristicValue(c, value)
        }

        @Deprecated("Called on Android 12 and older")
        override fun onCharacteristicChanged(g: BluetoothGatt, c: BluetoothGattCharacteristic) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) return
            @Suppress("DEPRECATION")
            val value = c.value
            if (value != null) onCharacteristicValue(c, value)
        }
    }

    private companion object {
        const val SCAN_TIMEOUT_MS = 10_000L
        const val SETTLE_MS = 1_500L
        const val CONNECT_TIMEOUT_MS = 15_000L
        const val PAIR_TIMEOUT_MS = 60_000L
        const val OP_TIMEOUT_MS = 5_000L
        const val DEFAULT_MTU = 23
        const val REQUESTED_MTU = 247
        const val GATT_INSUFFICIENT_AUTHENTICATION = 0x05
        const val GATT_INSUFFICIENT_ENCRYPTION = 0x0F
    }
}
