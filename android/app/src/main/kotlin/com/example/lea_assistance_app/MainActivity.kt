package fr.leassistant.lea_connect

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.lang.reflect.Method;
import java.util.List;
import android.os.Handler;
import java.util.Arrays
import java.util.UUID;

import android.bluetooth.*;
var hey = "1"; // set une variable temporaire a 1 pour eviter de renvoyer un null

class MainActivity: FlutterActivity() {
    private val CHANNEL = "sample.flutter.dev/bluetooth"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
      super.configureFlutterEngine(flutterEngine)
      // appel du channel
      MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
        call, result ->
        if (call.method == "getToken") {
            var lul = BluetoothToken.scan { msg ->
                hey = msg;
            }
            println(lul);
            val handler = Handler()
            //wait 10s le temps de get le token 
            handler.postDelayed({
                result.success(hey) // renvoie du token vers flutter
            }, 10000)
        }
      }
    }
}

private class BluetoothToken(device: BluetoothDevice, callback: (msg: String) -> Unit) : Thread() {
    private val device = device
    private val callback = callback
    override fun run() {
        try {
            val osocket = device.createRfcommSocketToServiceRecord(UUID.fromString("0e582616-851b-499d-9b4f-3d12056e72ee"))
            if (osocket == null)
                return
            val socket = osocket!!
            BluetoothAdapter.getDefaultAdapter()!!.cancelDiscovery()
            val buffer = ByteArray(1024)
            var bytes: Int = 0
            socket.connect()
            var str: String = ""
            while (true) {
                bytes = socket.getInputStream().read(buffer)
                str += String(Arrays.copyOfRange(buffer, 0, bytes))
                var done = false
                for (i in 0 until str.length)
                    if (str[i] == '\n') {
                        str = str.substring(0, i)
                        done = true
                    }
                if (done)
                    break
            }
            callback(str) //renvoie du token
            socket.close()
        } catch (connectException: IOException) {
            println("BLUETOOTH ERROR: ${connectException}") //erreur de connection au device (ça va arriver souvent c'est le temps que ça se connecte)
        }
    }

    companion object {
        fun scan(callback: (msg: String) -> Unit) {
            var adap = BluetoothAdapter.getDefaultAdapter()
            if (adap != null) {
                val devs = adap!!.getBondedDevices().toSet()
                if (devs != null) {
                    val dvs = devs!!
                    for (d in dvs) {
                        BluetoothToken(d, callback).start()
                    }
                }
            }
        }
    }
}
