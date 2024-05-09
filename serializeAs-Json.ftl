<#macro replicate source amount ><#--
    --><#list 0..<amount!0 as i><#--
        -->${source}<#--
    --></#list><#--
--></#macro>

<#macro cr><#--
    -->${'\n'}<#--
--></#macro>

<#assign __Json_reserved_keys = [
    "class"
] />

<#assign __Json_indentation = "    " />

<#function serializeAs_Json object = {} level = 0 >

<#--
    inspired by
    https://gist.github.com/ruudud/698035f96e860ef85d3f?permalink_comment_id=3788741#gistcomment-3788741
-->

    <#local out = "" />

    <#attempt>
        <#local _is_type = ( object?is_hash || object?is_hash_ex ) />
    <#recover>
        /* Unable to determine whether object is a hash */
        <#return _out>
    </#attempt>

    <#if _is_type >

        <#attempt>
            <#local _keys = object?keys?filter( name -> ! __Json_reserved_keys?seq_contains( name ) ) />
        <#recover>
            /* Unable to enumerate hash keys */
            <#return _out>
        </#attempt>

        <#assign _out >{<@cr/><#--

    --><#list _keys as _key ><#--
        --><#attempt>
                <#local _value = object[_key] />
            <#recover>
                /* Unable to acquire key ${_key} of object */
                <#continue>
            </#attempt><#--

        --><@replicate source = __Json_indentation amount = ( level + 1 ) /><#--
        -->"${_key}" : ${ serializeAs_Json( _value!"", ( level + 1 ) ) }<#--
        --><#sep>,<@cr/></#sep><#--
    --></#list><#--

    --><@cr/><@replicate __Json_indentation level />}<#--
    --></#assign>

        <#return _out />

    </#if>

    <#attempt>
        <#local _is_type = object?is_enumerable />
    <#recover>
        /* Unable to determine whether object is a sequence */
        <#return _out>
    </#attempt>

    <#if _is_type >

        <#assign _out >[<@cr/><#--

    --><#list object as _value ><#--
        --><@replicate source = __Json_indentation amount = ( level + 1 ) /><#--
        -->${ serializeAs_Json( _value!"", ( level + 1 ) ) }<#--
        --><#sep>,<@cr/></#sep><#--
    --></#list><#--

    --><@cr/><@replicate __Json_indentation level />]<#--
    --></#assign>

        <#return _out />

    </#if>

    <#attempt>
        <#local _is_type = ( object?is_number || object?is_boolean ) />
    <#recover>
        /* Unable to determine whether object is a number */
        <#return _out>
    </#attempt>

    <#if _is_type >

        <#assign _out >${object?c}<#--

    --></#assign>

        <#return _out />

    </#if>

    <#attempt>
        <#local _is_type = object?is_method />
    <#recover>
        /* Unable to determine whether object is a method */
        <#return _out>
    </#attempt>

    <#if _is_type >

        <#assign _out ><method><#--

    --></#assign>

        <#return _out />

    </#if>

    <#attempt>
        <#assign _out >"${object}"</#assign>
    <#recover>
        /* Unable to transform object to a string */
        <#return _out />
    </#attempt>

    <#return _out />

</#function>

<#assign mine = { "foo" : "bar", "class" : "should not be here", "guz" : 43 } />
<#assign mine2 = { "single array" : [ "value" ], "simple" : "property" } />
<#assign mine3 = { "single array" : [ "value" ], "simple" : "property", "hash" : { "array" : [ 42, 13, 77, -38 ], "subhash" : { "white" : true, "scalar": 42, "subsubhash" : { "simple" : "kai", "class" : "ignore me", "simple2" : "beach" } } } } />

${ serializeAs_Json( mine3 ) }
