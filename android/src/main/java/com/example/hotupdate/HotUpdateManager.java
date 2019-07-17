package com.example.hotupdate;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Environment;
import android.os.Handler;
import android.os.Message;
import android.telecom.Call;
import android.util.Log;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

/**
 * Created by apple on 2017/9/25.
 */

public class HotUpdateManager extends ReactContextBaseJavaModule {
    public Handler handler = null;
    private SharedPreferences share = null;
    private SharedPreferences.Editor editor = null;

    public void setHandler(Handler handler) {
        this.handler = handler;
    }

    public HotUpdateManager(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @ReactMethod
    public void downLoadBundleZipWithOption(ReadableMap options, Callback callback) {
        String zipPath = options.getString("zipPath");
        if(zipPath == null){
            WritableMap map = Arguments.createMap();
            map.putBoolean("result",false);
            map.putString("error","无效的地址");
            callback.invoke(map);
            return;
        }
        try {
            InputStream input = getReq(zipPath);
            if (input == null) {
                WritableMap map = Arguments.createMap();
                map.putBoolean("result",false);
                map.putString("error","无效的压缩包");
                callback.invoke(map);
                return;
            }
            String sdCardRoot = Environment.getExternalStorageDirectory().getAbsolutePath();
            mkdir(sdCardRoot, input);
            String AppPath = sdCardRoot + "/com.tplus.app";
            File appFile = new File(AppPath);
            if (!appFile.exists())
                appFile.mkdir();
            String Doc = AppPath + "/Document";
            File docFile = new File(Doc);
            if (!docFile.exists())
                docFile.mkdir();
            copyFolder(sdCardRoot + "/tmp/release_android", Doc);
            boolean isAbort = options.getBoolean("isAbort");
            if(isAbort)
                System.exit(0);
            WritableMap map = Arguments.createMap();
            map.putBoolean("result",true);
            map.putString("error","");
            callback.invoke(map);
        } catch (Exception e) {
            WritableMap map = Arguments.createMap();
            map.putBoolean("result",false);
            map.putString("error","异常发生");
            callback.invoke(map);
        }
    }

    @ReactMethod
    public void downLoadZipWithOpts(ReadableMap options, Callback callback) {
        WritableMap map = Arguments.createMap();
        map.putBoolean("result",false);
        map.putString("error","未实现");
        callback.invoke(map);
    }

    @ReactMethod
    public void unzipBundleToDir(String target, Callback callback) {
        WritableMap map = Arguments.createMap();
        map.putBoolean("result",false);
        map.putString("error","未实现");
        callback.invoke(map);
    }

    @ReactMethod
    public void setValueToUserStand(String value, String key,Callback callback) {
        share = getReactApplicationContext().getSharedPreferences("shareManager", Context.MODE_PRIVATE);
        editor = share.edit();
        editor.putString(key, value).commit();
    }

    @ReactMethod
    public void getValueWithkey(String key, Callback callback) {
        share = getReactApplicationContext().getSharedPreferences("shareManager", Context.MODE_PRIVATE);
        String value = share.getString(key, "");
        WritableMap map = Arguments.createMap();
        map.putString("value",value);
        callback.invoke(map);
    }

    @ReactMethod
    public void removeValueWithKey(String key, Callback callback) {
        share = getReactApplicationContext().getSharedPreferences("shareManager", Context.MODE_PRIVATE);
        editor = share.edit();
        editor.remove(key).commit();
        WritableMap map = Arguments.createMap();
        map.putBoolean("result", true);
        callback.invoke(map);
    }

    @ReactMethod
    public void killApp() {
        System.exit(0);
    }

    /**
     * get
     * @param UrlString
     * @return
     * @throws Exception
     */
    private InputStream getReq(String UrlString) throws Exception {
        try {
            if (UrlString == null)
                throw new Exception("路由为空");
            URL url = new URL(UrlString);
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setConnectTimeout(5000); // 超时
            connection.setRequestMethod("GET"); // 设置GET请求
            int responseCode = connection.getResponseCode();
            if (responseCode == 200)
                return connection.getInputStream();
            else
                return null;
        } catch (Exception ex) {
            throw ex;
        }
    }

    /**
     * 创建文件夹
     *
     * @param sdCardRoot
     * @param input
     * @throws Exception
     */
    private void mkdir(String sdCardRoot, InputStream input) throws Exception {
        String dirpath = sdCardRoot + "/tmp";
        File dirFile = new File(dirpath);
        if (!dirFile.exists())
            dirFile.mkdir();
        String zipPath = dirpath + "/release.zip";
        File zipFile = new File(zipPath);
        if (!zipFile.exists())
            zipFile.createNewFile();
        byte[] buffer = InputStreamTOByte(input);
        OutputStream output = new FileOutputStream(zipFile);
        output.write(buffer);
        UnZipFolder(zipPath, dirpath);
    }

    /**
     * 复制文件夹
     *
     * @param oldPath
     * @param newPath
     */
    public void copyFolder(String oldPath, String newPath) {

        try {
            (new File(newPath)).mkdirs(); //如果文件夹不存在 则建立新文件夹
            File a = new File(oldPath);
            String[] file = a.list();
            File temp = null;
            for (int i = 0; i < file.length; i++) {
                if (oldPath.endsWith(File.separator)) {
                    temp = new File(oldPath + file[i]);
                } else {
                    temp = new File(oldPath + File.separator + file[i]);
                }

                if (temp.isFile()) {
                    FileInputStream input = new FileInputStream(temp);
                    FileOutputStream output = new FileOutputStream(newPath + "/" +
                            (temp.getName()).toString());
                    byte[] b = new byte[1024 * 5];
                    int len;
                    while ((len = input.read(b)) != -1) {
                        output.write(b, 0, len);
                    }
                    output.flush();
                    output.close();
                    input.close();
                }
                if (temp.isDirectory()) {//如果是子文件夹
                    copyFolder(oldPath + "/" + file[i], newPath + "/" + file[i]);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

    }

    /**
     * 输入流转字节
     *
     * @param in
     * @return
     * @throws IOException
     */
    private byte[] InputStreamTOByte(InputStream in) throws IOException {
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        byte[] buffer = new byte[4096];
        int n = 0;
        while (-1 != (n = in.read(buffer))) {
            output.write(buffer, 0, n);
        }
        return output.toByteArray();
    }

    /**
     * 解压zip包
     *
     * @param zipFileString
     * @param outPathString
     * @throws Exception
     */
    private void UnZipFolder(String zipFileString, String outPathString) throws Exception {
        ZipInputStream inZip = new ZipInputStream(new FileInputStream(zipFileString));
        ZipEntry zipEntry;
        String szName = "";
        while ((zipEntry = inZip.getNextEntry()) != null) {

            szName = zipEntry.getName();
            System.out.println(szName);
            if (zipEntry.isDirectory()) {
                szName = szName.substring(0, szName.length() - 1);
                File folder = new File(outPathString + File.separator + szName);
                folder.mkdirs();
            } else {

                File file = new File(outPathString + File.separator + szName);
                file.createNewFile();
                FileOutputStream out = new FileOutputStream(file);
                int len;
                byte[] buffer = new byte[1024];
                while ((len = inZip.read(buffer)) != -1) {
                    out.write(buffer, 0, len);
                    out.flush();
                }
                out.close();
            }
        }
        inZip.close();
    }

    @Override
    public String getName() {
        return "HotUpdate";
    }
}
