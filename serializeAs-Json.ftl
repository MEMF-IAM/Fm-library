<#--
TODO::Add synopsis, version, author, function list and history here
-->

<#assign __Json_reserved_keys = [
    "class"
] />

<#assign __Json_indentation = "    " />

<#macro replicate source amount ><#--
    --><#list 0..<amount!0 as i><#--
        -->${source}<#--
    --></#list><#--
--></#macro>

<#macro cr><#--
    -->${'\n'}<#--
--></#macro>

<#function serializeAs_Json object = {} level = 0 >

<#--
    inspired by
    https://gist.github.com/ruudud/698035f96e860ef85d3f?permalink_comment_id=3788741#gistcomment-3788741
    and to lesser extent by
    https://github.com/MajorLeagueBaseball/freemarker-json/blob/master/json.ftl
-->

    <#local _out = "" />

    <#attempt>
        <#local _is_type = ( object?is_hash ) />
    <#recover>
        <#local _err >/* Unable to determine whether object is a hash */</#local>
        <#return _err />
    </#attempt>

    <#if _is_type >

        <#attempt>
            <#local _keys = object?keys?filter( name -> ! __Json_reserved_keys?seq_contains( name ) ) />
        <#recover>
            <#local _err >/* Unable to enumerate hash keys */</#local>
            <#return _err />
        </#attempt>

        <#local _out >{<@cr/><#--

    --><#list _keys as _key ><#--
        --><#attempt>
                <#local _value = object[_key] />
            <#recover>
                <#local _out>Unable to acquire key ${_key} of object */</#local>
                <#continue />
            </#attempt><#--

        --><@replicate source = __Json_indentation amount = ( level + 1 ) /><#--
        -->"${_key}" : ${ serializeAs_Json( _value!"", ( level + 1 ) ) }<#--
        --><#sep>,<@cr/></#sep><#--
    --></#list><#--

    --><@cr/><@replicate __Json_indentation level />}<#--
    --></#local>

        <#return _out />

    </#if>

    <#attempt>
        <#local _is_type = object?is_enumerable />
    <#recover>
        <#local _err >/* Unable to determine whether object is a sequence */</#local>
        <#return _err />
    </#attempt>

    <#if _is_type >

        <#local _out >[<@cr/><#--

    --><#list object as _value ><#--
        --><@replicate source = __Json_indentation amount = ( level + 1 ) /><#--
        -->${ serializeAs_Json( _value!"", ( level + 1 ) ) }<#--
        --><#sep>,<@cr/></#sep><#--
    --></#list><#--

    --><@cr/><@replicate __Json_indentation level />]<#--
    --></#local>

        <#return _out />

    </#if>

    <#attempt>
        <#local _is_type = ( object?is_number || object?is_boolean ) />
    <#recover>
        <#local _err >/* Unable to determine whether object is a number */</#local>
        <#return _err />
    </#attempt>

    <#if _is_type >

        <#local _out >${object?c}<#--

    --></#local>

        <#return _out />

    </#if>

    <#attempt>
        <#local _is_type = object?is_method />
    <#recover>
        <#local _err >/* Unable to determine whether object is a method */</#local>
        <#return _err />
    </#attempt>

    <#if _is_type >

        <#local _out >/* Methods are not supported */<#--

    --></#local>

        <#return _out />

    </#if>

    <#attempt>
        <#local _out >"${object}"<#--
        
    --></#local>
    <#recover>
        <#local _err >/* Unable to transform object to a string */</#local>
        <#return _err />
    </#attempt>

    <#return _out />

</#function>

<#--
<#assign mine = { "foo" : "bar", "class" : "should not be here", "guz" : 43 } />
<#assign mine2 = { "single array" : [ "value" ], "simple" : "property" } />
<#assign mine3 = { "single array" : [ "value" ], "simple" : "property", "hash" : { "array" : [ 42, 13, 77, -38 ], "subhash" : { "white" : true, "scalar": 42, "subsubhash" : { "simple" : "kai", "class" : "ignore me", "simple2" : "beach" } } } } />

${ serializeAs_Json( mine3 ) }
-->
