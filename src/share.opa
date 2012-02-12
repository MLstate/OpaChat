import stdlib.crypto
import file

/** Sharing module **/

DROP_TEXT = "Drop files here to share !"
TOO_BIG_TEXT = "File too big ! Try a smaller file..."

type OpaShare.file = {
  string name, // file name
  int size, // file size
  binary content, // file content
  string mimetype, // file mimetype
  Date.date date_uploaded, // upload date
  Date.date date_downloaded, // last download date
  int count, // download counter
  option(string) password, // file password
}

database intmap(OpaShare.file) /files

module OpaShare {

  client function init() {
    FilePlugin.hook_file_drop(Dom.select_class("dropzone"), waiting_file_treatment, handle_file_selection);
    FilePlugin.hook_file_chooser(#files, handle_file_selection);
  }

  client function waiting_file_treatment() {
    #share = <img src="/resources/img/facebook-loader.gif" alt="Uploading..."/>
    void
  }

  client function handle_file_selection(string name, string typ, int size, string content) {
    Log.info("File", "Sending {name} {typ} {content}")
    if (size > 10*1024*1024) {
      #share = <>{TOO_BIG_TEXT}</>
      void
    } else {
      #share = <>{DROP_TEXT}</>
      process_upload(name, typ, size, content)
      void
    }
  }

  exposed function process_upload(string name, string typ, int size, string content) {
    decoded_content =
      offset = Option.get(String.index("base64,", content)) + 7
      data = String.sub(offset, String.length(content)-offset, content)
      Crypto.Base64.decode2(data)
    os_file = {
      name: name,
      size: size,
      content: decoded_content,
      mimetype: typ,
      date_uploaded: Date.now(),
      date_downloaded: Date.now(),
      count: 0,
      password: none,
    }
    key = Db3.fresh_key(@/files)
    /files[key] <- os_file
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

}
