<#macro replicate source amount ><#--
    --><#list 0..<amount!0 as i><#--
        -->${source}<#--
    --></#list><#--
--></#macro>

<#function serializeAs_Json object = "" level = 0 >
    <#assign _tab = "    " />
    <#if object?is_hash || object?is_hash_ex ><#assign _out><#-- (HSH${level}) -->{
        <#list object as _key, _value><#--
        --><@replicate source = _tab amount = ( level + 1 ) /><#--
        -->"${_key}" : ${ serializeAs_Json( _value!"", ( level + 1 ) ) }<#sep>,
</#sep></#list>

<@replicate _tab level /><#-- (HSH${level})-->}</#assign>

    <#elseif object?is_enumerable ><#assign _out><#-- (ARR${level}) -->[
        <#list object as _value><#--
        --><@replicate source = _tab amount = ( level + 1 ) /><#--
        -->${ serializeAs_Json( _value!"", ( level + 1 ) ) }<#sep>,
</#sep></#list>

<@replicate _tab level /><#-- (ARR${level}) -->]</#assign>

    <#elseif object?is_number ><#assign _out><#-- (NUM${level}) -->${object}</#assign>

    <#else><#assign _out>"<#-- (OTH${level}) -->${object?trim}"</#assign>

    </#if>
    <#return _out />
</#function>

<#--

<#assign mine = { "single array" : [ "value" ], "simple" : "property", "hash" : { "array" : [ 42, 13, 77, -38 ], "subhash" : { "subsubhash" : { "simple" : "kai", "simple" : "beach" } } } } />
<#assign mine = [ "a", "b", "c", "d" ] />

${ serializeAs_Json ( mine ) }

-->
