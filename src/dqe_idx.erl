-module(dqe_idx).

%% API exports
-export([lookup/1, add/6, delete/6, expand/1]).

-type bucket() :: binary().
-type collection() :: binary().
-type metric() :: binary().
-type key() :: binary().
-type glob_metric() :: [binary() | '*'].
-type tag_name() :: binary().
-type tag_value() :: binary().

-type where() :: {tag_name(), tag_value()} |
                 {'and', where(), where()} |
                 {'or', where(), where()}.
-type lqry() :: {collection(), metric()} |
                {collection(), metric(), where()}.
-type eqry() :: {bucket(), [glob_metric()]}.

-callback lookup(lqry()) ->
    {ok, [{bucket(), key()}]} |
    {error, Error::term()}.

-callback expand(glob_metric()) ->
    {ok, [{bucket(), [metric()]}]} |
    {error, Error::term()}.

-callback add(Collection::collection(),
              Metric::metric(),
              Bucket::bucket(),
              Key::key(),
              TagName::tag_name(),
              TagValue::tag_value()) ->
    {ok, {MetricIdx::non_neg_integer(), TagIdx::non_neg_integer()}}|
    {error, Error::term()}.

-callback delete(Collection::collection(),
                 Metric::metric(),
                 Bucket::bucket(),
                 Key::key(),
                 TagName::tag_name(),
                 TagValue::tag_value()) ->
    ok |
    {error, Error::term()}.

%%====================================================================
%% API functions
%%====================================================================

-spec lookup(lqry()) ->
                    {ok, [{bucket(), key()}]} |
                    {error, Error::term()}.
lookup(Query) ->
    Mod = idx_module(),
    Mod:lookup(Query).

-spec expand(eqry()) ->
                    {ok, [{bucket(), key()}]} |
                    {error, Error::term()}.
expand(Query) ->
    Mod = idx_module(),
    Mod:expand(Query).

-spec add(Collection::collection(),
          Metric::metric(),
          Bucket::bucket(),
          Key::key(),
          TagName::tag_name(),
          TagValue::tag_value()) ->
                 {ok, {MetricIdx::non_neg_integer(), TagIdx::non_neg_integer()}}|
                 {error, Error::term()}.

add(Collection, Metric, Bucket, Key, TagName, TagValue) ->
    Mod = idx_module(),
    Mod:add(Collection, Metric, Bucket, Key, TagName, TagValue).

-spec delete(Collection::collection(),
             Metric::metric(),
             Bucket::bucket(),
             Key::key(),
             TagName::tag_name(),
             TagValue::tag_value()) ->
                    {ok, {MetricIdx::non_neg_integer(), TagIdx::non_neg_integer()}}|
                    {error, Error::term()}.

delete(Collection, Metric, Bucket, Key, TagName, TagValue) ->
    Mod = idx_module(),
    Mod:add(Collection, Metric, Bucket, Key, TagName, TagValue).

%%====================================================================
%% Internal functions
%%====================================================================
idx_module() ->
    application:get_env(dqe, lookup_module, dqe_idx_ddb).
