import {NativeModules} from 'react-native'

const {HotUpdate} = NativeModules

module.exports = {
  documentDir: HotUpdate.documentDir,
  cacheDir: HotUpdate.cacheDir,
  downLoadBundleZipWithOption: function (options, callback) {
    HotUpdate.downLoadBundleZipWithOption(options, callback)
  },
  downLoadZipWithOpts: function (options, callback) {
    HotUpdate.downLoadZipWithOpts(options, callback)
  },
  unzipBundleToDir: function (target, callback) {
    HotUpdate.unzipBundleToDir(target, callback)
  },
  setValueToUserStand: function (value, key, callback) {
    HotUpdate.setValueToUserStand(value, key, callback)
  },
  getValueWithkey: function (key, callback) {
    HotUpdate.getValueWithkey(key, callback)
  },
  removeValueWithKey: function (key, callback) {
    HotUpdate.removeValueWithKey(key, callback)
  },
  killApp: function () {
    HotUpdate.killApp()
  }
}
