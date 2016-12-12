(function() {
    document.addEventListener('DOMContentLoaded', function() {
        var fields = document.getElementsByClassName('file-field');
        for (var i = 0; i < fields.length; i++) {
            var field = fields[i];
            var input = field.getElementsByTagName('input')[0];
            var image = field.getElementsByTagName('img')[0];
            var state = field.getElementsByClassName('file-field-name')[0];

            input.onchange = function() {
                state.className = 'file-field-name selected';
                state.innerHTML = this.value.split(/[\/\\]/).reverse()[0];
                var uploadButton = this.form.querySelector('[value="upload"]');
                if (uploadButton) {
                    uploadButton.setAttribute('data-enabled', '1');
                }
                
                if (this.files && this.files[0] && typeof FileReader !== "undefined") {
                    var reader = new FileReader();

                    reader.onload = function (e) {
                        image.className = 'changed';
                        image.src = e.target.result;
                    };

                    reader.readAsDataURL(this.files[0]);
                }
            }
        }
    }, false);
})();
