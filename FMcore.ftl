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

<#function var_dump var depth = 0 >
    <#local _out = ""?default />
    <#if var?is_sequence>
        <#local _out>
            <#list var as _value>
                <@replicate source = __Json_indentation amount = ( depth ) /><#--
                -->item ${_value?index}:<@cr/><#--
                -->${var_dump( _value, ( depth + 1 ) )}
            </#list>
        </#local>
    <#elseif var?is_hash >
        <#local _out>
            <#list var as _index, _value>
                <@replicate source = __Json_indentation amount = ( depth ) /><#--
                -->key  ${_index}:<@cr/><#--
                -->${var_dump( _value, ( depth + 1 ) )}
            </#list>
        </#local>
    <#elseif var?is_string >
        <#local _out >strg : ${var}</#local>
    <#elseif var?is_number >
        <#local _out >nmbr : ${var?string}</#local>
    <#elseif var?is_boolean >
        <#local _out >bool : ${var?string("true","false")}</#local>
    </#if>
    <#local _out ><#--
        --><@replicate source = __Json_indentation amount = ( depth ) /><#--
        -->${_out}<#--
        --><@cr/><#--
    --></#local>
    <#return _out />
</#function>


<#assign h = { "foo" : [ "bar", "guz" ], "kai" : { "yum" : "zol" } } />
<#assign s = [ "foo", "bar", "guz", "kai" ] />
<#assign n = 42.15 />
<#assign b = false />
<#assign t = "hello world" />
${var_dump(h)}
-->

<#function addTo_collection object index value overwrite = false >

<#-- not ( object and index ) ? -> bail out -->
    <#if ! ( object?? && index?? ) >
        <#return undefined />
    </#if>

<#--assign workobject -->
    <#local _object = object >

<#-- index is a sequence ? -->
    <#if ! index?is_enumerable >
<#--    assign workpath by splitting index on dot -->
        <#local _path = index?trim?split(".") />
    <#else>
<#--    assign workpath -->
        <#local _path = index />
    </#if>

<#--get first node -->
    <#local _node = _path?first />
<#--determine eop -->
    <#local _eop = _path?size == 1 />

<#--workobject is not a hash or sequence ? -->
    <#if ! ( _object?is_hash || _object?is_enumerable ) >
<#--    single value, turn into sequence -->
        <#local _object = [ object ] />
    </#if>

<#--workobject is a hash ? -->
    <#if _object?is_hash >
<#--    get keys -->
        <#local _keys = ( _object?keys?filter( name -> ! __Json_reserved_keys?seq_contains( name ) ) )![] />
<#--    assign accu empty hash -->
        <#local _clone = {} />
    <#elseif _object?is_enumerable >
<#--workobject is a seqence ? -->
<#--    get keys = 0..(workobject?size!1 - 1) -->
        <#local _keys = [ 0 .. ( _object?size!1 - 1 ) ] />
<#--    assign accu empty sequence -->
        <#local _clone = [] />
    <#else>
<#--    workobject is not a hash or sequence, other types currently unsupported -->
        <#return undefined />
    </#if>

<#--assign commited false -->
    <#local _committed = false />

<#--loop keys -->
    <#list _keys as _key >
<#--    get object[key]'s value -->
        <#attempt>
            <#local _accu = _object[_key] />
        <#recover>
            <#continue />
        </#attempt>

<#--    key equals node ? -->
        <#if _node == _key >
<#--        are we at end of path ? -->
            <#if _eop >
<#-- should we assert here that given value *can* be added to object[_key]'s value, i.e. of the same type?
    at least, if the current value is a scalar, it should become a sequence
    and if the current value is a hash, the value added must be a hash tuple
-->
<#--            overwrite ? -->
                <#if overwrite >
<#--                add value to accu -->
                    <#local _accu = value />
<#--            append ? -->
                <#else>
<#--                workobject not a hash or sequence ? -->
                    <#if ! ( _accu?is_enumerable || _accu?is_hash ) >
<#--                    single value, turn into sequence as cannot 'invent' as hash key -->
                        <#local _accu = [ _accu ] />
                    </#if>
<#--                add workobject[key] + value to accu -->
                    <#attempt>
                        <#local _accu += value />
                    <#recover>
                        <#continue />
                    </#attempt>
                </#if>
<#--        are we not at end of path ? -->
            <#else>
<#--            add ( recurse workobject[key] keys[1..] value overwrite ) to accu -->
                <#local _accu = addTo_collection( _accu _path[1..] value overwrite ) />
            </#if>
<#--        mark value as processed -->
            <#local _committed = true />
        </#if>

<#--    add computed value to clone -->
        <#if _clone?is_enumerable >
            <#local _clone += _accu />
        <#else>
            <#local _clone += { _key : _accu } />
        </#if>

<#--    at end of list and value not added yet ? -->
        <#if _key?is_last && ! _committed >
            <#if _eop >
<#--            clone is sequence ? -->
                <#if _clone?is_enumerable >
<#--                add value as new entry -->
                    <#local _clone += value />
<#--            clone is hash ? -->
                <#elseif _clone?is_hash >
<#--                add value as new entry -->
                    <#local _clone += { _node : value } />
                </#if>
            <#else>
<#--            clone is sequence ? -->
                <#if _clone?is_enumerable >
<#--                add ( recurse [empty array] keys[1..] value overwrite ) to clone -->
                    <#local _clone += addTo_collection( [] _path[1..] value overwrite ) />
<#--            clone is hash ? -->
                <#elseif _clone?is_hash >
<#--                add ( recurse [empty hash] keys[1..] value overwrite ) to clone -->
                    <#local _clone += addTo_collection( {} _path[1..] value overwrite ) />
                </#if>
            </#if>
        </#if>
    </#list>

    <#return _clone />

</#function>

<#--
<#assign mine = { "foo" : "bar", "class" : "should not be here", "guz" : { "kai" : 43 } } />
<#assign mine >
{
        "results" : {
            "start" : "2024-05-13T08:20:31Z",
                "unlink" : {
                "successful" : [
                    "37838eb4-3ef6-4570-98df-75c03fffa37d",
                    "13e9352d-edfc-46e4-8e2e-76d711a89655"
                ],
                    "summary" : "2 middelen ontkoppeld."
                }
                },
                    "change" : {
            "id" : "4dfa141a-4889-43c6-8f84-6bc9f3c71109",
                "number" : "W2405 0046"
            },
                "person" : {
            "id" : "8ed950f8-4cba-4d30-bee8-f9a2099f2d8f",
                "name" : "Kikkert, Rudi"
            },
                "assets" : {
            "types" : {
                "count" : "1",
                    "type" : {
                    "F4D3D1C1-1EE7-4A77-B468-76D722FB27C1" : [
                        "f382b414-cf91-4972-b758-cad88229eeb4"
                    ]
                    }
                    },
                        "link" : {
                "a852865b-905a-4519-b29f-f79c9cd89ff0" : "FT0040",
                    "f7396f30-a61c-4876-acdd-5701f73fb67a" : "FT0044"
                },
                    "unlink" : {
                "37838eb4-3ef6-4570-98df-75c03fffa37d" : "FT0041",
                    "13e9352d-edfc-46e4-8e2e-76d711a89655" : "FT0042"
                }
                }
                }
</#assign>
<#assign mine = ( mine?eval_json )!{} />
<#assign res = addTo_collection( mine, "kai", 99 ) />
<#assign res = addTo_collection( mine, [ "guz", "kai" ], [ 99, 100 ] ) />
<#assign res = addTo_collection( mine, [ "guz", "kai" ], { "new" : "hash" }, true ) />
<#assign res = addTo_collection( res, [ "guz", "kai" ], { "newest" : "one" }, false ) />
<#assign res = addTo_collection( res, "guz.yum", "additional", false ) />
${var_dump( res["guz"] )}
-->

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
        /* Unable to determine whether object is a hash */
        <#return _out />
    </#attempt>

    <#if _is_type >

        <#attempt>
            <#local _keys = object?keys?filter( name -> ! __Json_reserved_keys?seq_contains( name ) ) />
        <#recover>
            /* Unable to enumerate hash keys */
            <#return _out />
        </#attempt>

        <#assign _out >{<@cr/><#--

    --><#list _keys as _key ><#--
        --><#attempt>
                <#local _value = object[_key] />
            <#recover>
                /* Unable to acquire key ${_key} of object */
                <#continue />
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
        <#return _out />
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
        <#return _out />
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
        <#return _out />
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

<#--
<#assign mine = { "foo" : "bar", "class" : "should not be here", "guz" : 43 } />
<#assign mine2 = { "single array" : [ "value" ], "simple" : "property" } />
<#assign mine3 = { "single array" : [ "value" ], "simple" : "property", "hash" : { "array" : [ 42, 13, 77, -38 ], "subhash" : { "white" : true, "scalar": 42, "subsubhash" : { "simple" : "kai", "class" : "ignore me", "simple2" : "beach" } } } } />

${ serializeAs_Json( mine3 ) }
-->
