<#macro template body title="Sala Blog">
<#assign styles=["css/bootstrap.min.css","css/asciidoctor.css","css/base.css","css/prettify.css"]/>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8"/>
    <title><#if (content.title)??><#escape x as x?xml>${content.title}</#escape><#else>${title}</#if></title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="">
    <meta name="author" content="">
    <meta name="keywords" content="">
    <meta name="generator" content="JBake">

    <!-- Le styles -->
    <#list styles as style>
        <link href="<#if (content.rootpath)??>${content.rootpath}<#else></#if>${style}" rel="stylesheet">
    </#list>

    <!-- HTML5 shim, for IE6-8 support of HTML5 elements -->
    <!--[if lt IE 9]>
    <script src="<#if (content.rootpath)??>${content.rootpath}<#else></#if>js/html5shiv.min.js"></script>
    <![endif]-->

    <!-- Fav and touch icons -->
    <!--<link rel="apple-touch-icon-precomposed" sizes="144x144" href="../assets/ico/apple-touch-icon-144-precomposed.png">
    <link rel="apple-touch-icon-precomposed" sizes="114x114" href="../assets/ico/apple-touch-icon-114-precomposed.png">
    <link rel="apple-touch-icon-precomposed" sizes="72x72" href="../assets/ico/apple-touch-icon-72-precomposed.png">
    <link rel="apple-touch-icon-precomposed" href="../assets/ico/apple-touch-icon-57-precomposed.png">-->
    <link rel="shortcut icon" href="<#if (content.rootpath)??>${content.rootpath}<#else></#if>favicon.ico">
</head>
<body onload="prettyPrint()">
<div id="wrap">
    <#include "../common/navbar.ftl"/>
    <div class="container">
    <#if body?? && body?is_macro>
        <@body/>
    </#if>
    </div>
    <div id="push"></div>
</div>

<div id="footer">
    <div class="container">
        <p class="muted credit">&copy; 2014 | Mixed with <a href="http://getbootstrap.com/">Bootstrap v3.1.1</a> | Baked with <a href="http://jbake.org">JBake ${version}</a></p>
    </div>
</div>

<!-- Le javascript
================================================== -->
<!-- Placed at the end of the document so the pages load faster -->
<script src="<#if (content.rootpath)??>${content.rootpath}<#else></#if>js/jquery-1.11.1.min.js"></script>
<script src="<#if (content.rootpath)??>${content.rootpath}<#else></#if>js/bootstrap.min.js"></script>
<script src="<#if (content.rootpath)??>${content.rootpath}<#else></#if>js/prettify.js"></script>
<!-- Yandex.Metrika counter -->
<script type="text/javascript">
    (function (d, w, c) {
        (w[c] = w[c] || []).push(function() {
            try {
                w.yaCounter36590025 = new Ya.Metrika({
                    id:36590025,
                    clickmap:true,
                    trackLinks:true,
                    accurateTrackBounce:true
                });
            } catch(e) { }
        });

        var n = d.getElementsByTagName("script")[0],
                s = d.createElement("script"),
                f = function () { n.parentNode.insertBefore(s, n); };
        s.type = "text/javascript";
        s.async = true;
        s.src = "https://mc.yandex.ru/metrika/watch.js";

        if (w.opera == "[object Opera]") {
            d.addEventListener("DOMContentLoaded", f, false);
        } else { f(); }
    })(document, window, "yandex_metrika_callbacks");
</script>
<noscript><div><img src="https://mc.yandex.ru/watch/36590025" style="position:absolute; left:-9999px;" alt="" /></div></noscript>
<!-- /Yandex.Metrika counter -->
</body>
</html>
</#macro>