xquery version "1.0-ml";
declare namespace html = "http://www.w3.org/1999/xhtml";

xdmp:set-response-content-type("text/html; charset=utf-8"),
'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
<html xmlns="http://www.w3.org/1999/xhtml" lang="en"> &gt; This works...
<script>
var five = 5;
var is_more = function(n) {{
    if n &lt; 2 {{
        return "Yes";
    }} else {{
        return "no";
    }};
}}
console.log(is_more(five));
</script>
</html>