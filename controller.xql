xquery version "3.1";

declare namespace json="http://www.json.org";
declare namespace control="http://exist-db.org/apps/dashboard/controller";
declare namespace output="http://exquery.org/ns/rest/annotation/output";
declare namespace rest="http://exquery.org/ns/restxq";

import module namespace login="http://exist-db.org/xquery/login" at "resource:org/exist/xquery/modules/persistentlogin/login.xql";

import module namespace restxq="http://exist-db.org/xquery/restxq" at "modules/restxq.xql";
import module namespace packages="http://exist-db.org/apps/dashboard/packages/rest" at "modules/packages.xql";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

declare variable $local:login-domain := "org.exist.login";
declare function local:user-allowed ($user) as xs:boolean {
    (
        not(empty($user)) and
        not($user = "guest") and
        sm:is-dba($user)
    )
};

let $login := login:set-user($local:login-domain, (), false())
let $user := request:get-attribute($local:login-domain || ".user")

return
if (not(local:user-allowed($user)))
then (
    response:set-status-code(401),
    <response>
        <user>{$user}</user>
        <path>{$exist:path}</path>
        <error>Wrong user or password</error>
    </response>
)
else if ($exist:path eq '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="/"/>
    </dispatch>
else if ($exist:path = "/")
then (
(: forward root path to index.xql :)
      <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
          <forward url="index.html"/>
          <cache-control cache="yes"/>
      </dispatch>
)
else if (matches($exist:path, ".xql/?$"))
then (
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        { $user }
        <set-attribute name="$exist:path" value="{$exist:path}"/>
    </dispatch>
)
else if (starts-with($exist:path, "/packages/"))
then (
    let $log := util:log("info", $exist:path)
    let $funcs := util:list-functions("http://exist-db.org/apps/dashboard/packages/rest")
    return (
      response:set-header("Cache-Control", "no-cache"),
      restxq:process($exist:path, $funcs)
    )
)
else (
    response:set-status-code(404),
    <response>
        <user>{$user}</user>
        <path>{$exist:path}</path>
        <error>Not found</error>
    </response>
)
