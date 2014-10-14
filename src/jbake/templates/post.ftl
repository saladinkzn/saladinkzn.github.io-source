<#include "templates/mainTemplate.ftl">
<#macro body>
    <div class="page-header">
        <h1><#escape x as x?xml>${content.title}</#escape></h1>
    </div>

    <p><em>${content.date?string("dd MMMM yyyy")}</em></p>

    <p>${content.body}</p>

    <hr />
</#macro>
<@template body=body/>