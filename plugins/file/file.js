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
};

##register hook_file_drop : string, (-> void), (string, string, int, string -> void) -> void
##args(sel, waiting_cb, cb)
{
    $(document).on("drop", function(e) {
        e.stopPropagation();
        e.preventDefault();
        if (!$(e.target).hasClass("dropzone") &&
	    !$(e.target).parent().hasClass("dropzone")) return;
        waiting_cb();
	console.log(e);
        var oe = e.originalEvent;
        $(oe.dataTransfer.files).each(
	    function(key, file) {
		file_to_content(file, cb);
	    }
        );
    }).on("dragenter, dragexit, dragover", noop_handler);
}

##register hook_file_chooser : string, (string, string, int, string -> void) -> void
##args(sel, cb)
{
    $(sel).on("change", function(e) {
        for (var f in e.target.files) {
            var file = e.target.files[f];
            file_to_content(file, cb);
        }
    });
}
