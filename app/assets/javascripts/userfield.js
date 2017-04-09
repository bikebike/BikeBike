(function() {
    function find_user(email, f) {
        var request = new XMLHttpRequest();
        request.open('POST', '/user/find', true);
        request.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded;charset=UTF-8');
        request.setRequestHeader('X-CSRF-Token', encodeURI(document.querySelector('meta[name="csrf-token"]').getAttribute('content')));
        request.send('e=' + encodeURI(email));
        request.onreadystatechange = function() {
            if (request.readyState == 4) {
                if (request.status == 200) {
                    f(JSON.parse(request.responseText));
                } else {
                    f({error: request.status});
                }
            }
        }
    }
    document.addEventListener('DOMContentLoaded', function() {
        var fields = document.getElementsByClassName('user-field');
        for (var i = 0; i < fields.length; i++) {
            var field = fields[i];
            var input = field.getElementsByTagName('input')[0];
            var name = field.getElementsByClassName('user-name')[0];
            
        }
    }, false);
})();
