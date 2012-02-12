package file

/**
 * Plugin inspired by pixlpaste : https://github.com/alokmenghrajani/pixlpaste
 * and http://www.thebuzzmedia.com/html5-drag-and-drop-and-file-api-tutorial/
 * and http://www.deadmarshes.com/Blog/20110413023355.html
 */
module FilePlugin {

  client function hook_file_drop(dom, waiting_callback, callback) {
    (%%file.hook_file_drop%%)(Dom.to_string(dom), waiting_callback, callback)
  }

  client function hook_file_chooser(dom, callback) {
    (%%file.hook_file_chooser%%)(Dom.to_string(dom), callback)
  }

}
