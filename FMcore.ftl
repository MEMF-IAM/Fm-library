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

<#macro write_comment what type = "json" ><#--

--><#compress>

    <#local _entry = what?trim />

    <#switch type?lower_case >
        <#case "json">/* ${ _entry } */<#break />
        <#case "html"><#noparse><!-- </#noparse>${ _entry }<#noparse> --></#noparse><#break />
        <#case "raw"><#-- fallin' thru -->
        <#default>${ _entry }
    </#switch>

    </#compress><#--

--></#macro>

<#macro addTo_journal what comment = false type = "json" ><#--

--><#compress>

    <#if ! .globals.__journal?? >
        <#global __journal = [] />
    </#if>
    <#if ! .globals.__journal?is_sequence >
        <#global __journal = [] />
    </#if>

    <#local _entry = what!"" />

    <#switch type?lower_case >
        <#case "json"><#local _entry = _entry?json_string /><#break />
        <#case "html"><#local _entry = _entry?html        /><#break />
        <#case "raw">                                       <#-- fallin' thru -->
        <#default>    <#local _entry = _entry?cn          />
    </#switch>

    <#global __journal += [ _entry ] />

    <#if comment!false >

        <@write_comment what = what type = type />

    </#if>

    </#compress><#--
    
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

<#function addTo_collection object index value overwrite = false >

    <#-- not ( object and index ) ? -> bail out -->
    <#if ! ( object?? && index?? ) >
        <#return undefined />
    </#if>

    <#-- assign workobject -->
    <#local _object = object >

    <#-- index is a sequence ? -->
    <#if ! index?is_enumerable >
        <#-- assign workpath by splitting index on dot -->
        <#local _path = index?trim?split(".") />
    <#else>
        <#-- assign workpath -->
        <#local _path = index />
    </#if>

    <#-- get first node -->
    <#local _node = _path?first />
    <#-- determine eop -->
    <#local _eop = _path?size == 1 />

    <#-- workobject is not a hash or sequence ? -->
    <#if ! ( _object?is_hash || _object?is_enumerable ) >
        <#-- single value, turn into sequence -->
        <#local _object = [ object ] />
    </#if>

    <#-- workobject is a hash ? -->
    <#if _object?is_hash >
        <#-- get keys -->
        <#local _keys = ( _object?keys?filter( name -> ! __Json_reserved_keys?seq_contains( name ) ) )![] />
        <#-- assign accu empty hash -->
        <#local _clone = {} />
    <#-- workobject is a seqence ? -->
    <#elseif _object?is_enumerable >
        <#-- get keys = 0..(workobject?size!1 - 1) -->
        <#local _keys = [ 0 .. ( _object?size!1 - 1 ) ] />
        <#-- assign accu empty sequence -->
        <#local _clone = [] />
    <#-- workobject is not a hash or sequence ? -->
    <#else>
        <#-- bail out, other types currently unsupported -->
        <#return undefined />
    </#if>

    <#-- assign commited false -->
    <#local _committed = false />

    <#-- loop keys -->
    <#list _keys as _key >
        <#-- get object[key]'s value -->
        <#attempt>
            <#local _accu = _object[_key] />
        <#recover>
            <#continue />
        </#attempt>

        <#-- key equals node ? -->
        <#if _node == _key >
            <#-- are we at end of path ? -->
            <#if _eop >
                <#-- should we assert here that given value *can* be added to object[_key]'s value, i.e. of the same type?
                    at least, if the current value is a scalar, it should become a sequence
                    and if the current value is a hash, the value added must be a hash tuple
                -->
                <#-- overwrite ? -->
                <#if overwrite >
                    <#-- add value to accu -->
                    <#local _accu = value />
                <#-- append ? -->
                <#else>
                    <#-- workobject not a hash or sequence ? -->
                    <#if ! ( _accu?is_enumerable || _accu?is_hash ) >
                        <#-- single value, turn into sequence because cannot 'invent' a hash key -->
                        <#local _accu = [ _accu ] />
                    </#if>
                    <#-- add workobject[key] + value to accu -->
                    <#attempt>
                        <#-- value and accu are both either sequence or hash ? -->
                        <#if ( _accu?is_sequence && value?is_sequence ) || ( _accu?is_hash && value?is_hash ) >
                            <#-- add the value as is, and let operator perform built-in appending -->
                            <#local _accu += value >
                        <#-- accu is a sequence but value is something else ? -->
                        <#elseif _accu?is_sequence >
                            <#-- add value as another item to accu -->
                            <#local _accu += [ value ] />
                        <#elseif _accu?is_hash >
                            <#-- add value as an anonymous tuple to accu -->
                            <#local _accu += { ( _accu?keys?size++ )?string["key000"] : value } />
                        </#if>
                    <#recover>
                        <#continue />
                    </#attempt>
                </#if>
            <#-- are we not at end of path ? -->
            <#else>
                <#-- add ( recurse workobject[key] keys[1..] value overwrite ) to accu -->
                <#local _accu = addTo_collection( _accu _path[1..] value overwrite ) />
            </#if>
            <#-- mark value as processed -->
            <#local _committed = true />
        </#if>

        <#-- add computed value to clone -->
        <#if _clone?is_enumerable >
            <#local _clone += _accu />
        <#else>
            <#local _clone += { _key : _accu } />
        </#if>
    </#list>

    <#-- at end of list and value not added yet ? -->
    <#if ! _committed >
        <#if _eop >
            <#-- clone is sequence ? -->
            <#if _clone?is_enumerable >
                <#-- add value as new entry -->
                <#local _clone += value />
            <#-- clone is hash ? -->
            <#elseif _clone?is_hash >
                <#-- add value as new entry -->
                <#local _clone += { _node : value } />
            </#if>
        <#else>
            <#-- clone is sequence ? -->
            <#if _clone?is_enumerable >
                <#-- add ( recurse [empty array] keys[1..] value overwrite ) to clone -->
                <#local _clone += addTo_collection( [] _path[1..] value overwrite ) />
            <#-- clone is hash ? -->
            <#elseif _clone?is_hash >
                <#-- add ( recurse [empty hash] keys[1..] value overwrite ) to clone -->
                <#local _clone += addTo_collection( {} _path[1..] value overwrite ) />
            </#if>
        </#if>
    </#if>

    <#return _clone />

</#function>

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
