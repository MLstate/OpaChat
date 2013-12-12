import stdlib.crypto
import file

/** Sharing module **/

MAX_SIZE = 5
DROP_TEXT = "Drop files here to share them"
LIMIT_TEXT = "File size limit exceeded! ({MAX_SIZE}Mb)"

type OpaShare.file = {
  int id, // file ID
  string name, // file name
  int size, // file size
  binary content, // file content
  string mimetype, // file mimetype
  Date.date date_uploaded, // upload date
  Date.date date_downloaded, // last download date
  int count, // download counter
  option(string) password, // file password
}

database opa_share {
  OpaShare.file /files[{id}]
}

module OpaShare {

  client function init(callback) {
    FilePlugin.hook_file_drop(Dom.select_class("dropzone"), waiting_file_treatment, handle_file_selection(callback));
    FilePlugin.hook_file_chooser(#files, handle_file_selection(callback));
  }

  client function waiting_file_treatment() {
    #share = <img src="/resources/img/facebook-loader.gif" alt="Uploading..."/>
    void
  }

  client function handle_file_selection(callback)(string name, string mimetype, int size, string content) {
    if (size > MAX_SIZE*1024*1024) {
      #share = <>{LIMIT_TEXT}</>
      void
    } else {
      #share = <>{DROP_TEXT}</>
      _ = process_upload(name, mimetype, size, content, callback)
      void
    }
  }

  private function fresh_key() {
    Date.in_milliseconds(Date.now_gmt())
  }

  exposed function process_upload(string name, string mimetype, int size, string content, callback) {
    decoded_content =
      match (String.index("base64,", content)) {
      case {none}: binary_of_string(content)
      case {some:i}:
        offset = i + 7
        data = String.sub(offset, String.length(content)-offset, content)
        Crypto.Base64.decode(data)
      }
    os_file = {
      id: fresh_key(),
      ~name,
      ~size,
      content: decoded_content,
      ~mimetype,
      date_uploaded: Date.now(),
      date_downloaded: Date.now(),
      count: 0,
      password: none,
    }
    /opa_share/files[id==os_file.id] <- os_file
    callback(name, mimetype, os_file.id)
  }

  function html() {
    <div id=#drop_area class="dropzone">
      <p id=#share
         onclick={function(_){Dom.trigger(#files, {click})}}>
        {DROP_TEXT}
      </p>
      <input id=#files type="file" multiple="multiple"/>
    </div>
  }

  function get(key) {
    ?/opa_share/files[{id:key}]
  }

}
