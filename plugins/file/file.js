var noop_handler = function(e) {
    e.stopPropagation();
    e.preventDefault();
};

// get the content of a file and pass it to cb
function file_to_content(file, cb) {
    if (window.FileReader) {
	var reader = new FileReader();
	reader.onload = function(e) {
        // if (file.size > 10*1024*1024) return;
        cb(file.name, file.type, file.size, e.target.result);
	};
	reader.readAsDataURL(file);
    } else {
	console.log("Uploading "+file.name);
	var http = new XMLHttpRequest();
	var form = new FormData();
	form.append('file', file);
	http.open('POST', '/upload');
	http.send(form);
    }
}

/** @register { string, (-> void), (string, string, int, string -> void) -> void }
*/
function hook_file_drop(sel, waiting_cb, cb) {
    $(document).on("drop", function(e) {
        e.stopPropagation();
        e.preventDefault();
        if (!$(e.target).hasClass("dropzone") &&
            !$(e.target).parent().hasClass("dropzone")) return;
        waiting_cb();
        var oe = e.originalEvent;
        $(oe.dataTransfer.files).each(
        function(key, file) {
            file_to_content(file, cb);
        }
        );
    }).on("dragenter, dragexit, dragover", noop_handler);
}

/** @register { string, (string, string, int, string -> void) -> void }
*/
function hook_file_chooser(sel, cb) {
    $(sel).on("change", function(e) {
        $(e.target.files).each(
	    function(key, file) {
		file_to_content(file, cb);
    }
	);
    });
}
