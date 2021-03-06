%%%-------------------------------------------------------------------
%%% @copyright (C) 2016, Project-FiFo UG
%%% @doc
%%% Call back module and wrapper for the Dalmatiner Query Engine
%%% Indexer. This module should be used in place of calling
%%% different indexer backends.
%%% @end
%%% Created : 16 Apr 2016 by Heinz Nikolaus Gies <heinz@licenser.net>
%%%-------------------------------------------------------------------
-module(dqe_idx).

-behaviour(dqe_idx).

%% API exports
-export([init/0,
         lookup/4, lookup/5, lookup_tags/1,
         collections/0, metrics/1, metrics/2, metrics/3,
         namespaces/1, namespaces/2,
         tags/2, tags/3, values/3, values/4, expand/2,
         add/5, add/6, update/5, touch/1,
         delete/4, delete/5]).

-type timestamp() :: pos_integer() | undefined | now.
-type bucket() :: binary().
-type collection() :: binary().
-type metric() :: [binary()].
-type key() :: [binary()].
-type glob_metric() :: [binary() | '*'].
-type namespace() :: binary().
-type tag_name() :: binary().
-type tag() :: {tag, Namespace::namespace(), TagName::tag_name()}.
-type tag_value() :: binary().
-type tags() :: [{Namespace::namespace(), TagName::tag_name(),
                  Value::tag_value()}].

-type opt_metric() :: metric() | undefined.

-type where() :: {'=',  tag(), tag_value()} |
                 {'exists', tag() } |
                 {'and', where(), where()} |
                 {'or', where(), where()}.

-type lqry() :: {in, collection(), opt_metric()} |
                {in, collection(), opt_metric(), where()}.

-type group_by_field() :: binary().


-type opts() :: [term()].

-type start() :: non_neg_integer().

-type finish() :: pos_integer().

-type touch_point() :: {Bucket::bucket(),
                        Key::key(),
                        Time::timestamp()} |
                       {Bucket::bucket(),
                        Key::key()}.

-type touch_points() :: [touch_point()].

-type endpoint() ::
        default |
        null.

-type lookup_result() ::
        {bucket(), key(), [{start(), finish(), endpoint()}]}.

-export_type([bucket/0, collection/0, metric/0, key/0,
              glob_metric/0, tag_name/0, tag_value/0,
              where/0, lqry/0, group_by_field/0, timestamp/0,
              touch_points/0, touch_point/0]).

-callback init() ->
    ok |
    {error, Error::term()}.

-callback lookup(lqry(), start(), finish(), opts()) ->
    {ok, [lookup_result()]} |
    {error, Error::term()}.

-callback lookup(lqry(), start(), finish(), [group_by_field()], opts()) ->
    {ok, [{lookup_result(), [tag_value()]}]} |
    {error, Error::term()}.

-callback lookup_tags(lqry()) ->
    {ok, tags()} |
    {error, Error::term()}.

-callback collections() ->
    {ok, [collection()]} |
    {error, Error::term()}.

-callback metrics(Collection::collection()) ->
    {ok, [metric()]} |
    {error, Error::term()}.

-callback metrics(Collection::collection(), Where::where()) ->
    {ok, [metric()]} |
    {error, Error::term()}.

-callback metrics(Collection::collection(), Prefix::metric(),
                  Depth::pos_integer()) ->
    {ok, [metric()]} |
    {error, Error::term()}.

-callback namespaces(Collection::collection()) ->
    {ok, [namespace()]} |
    {error, Error::term()}.

-callback namespaces(Collection::collection(), Metric::metric()) ->
    {ok, [namespace()]} |
    {error, Error::term()}.

-callback tags(Collection::collection(), Namespace::namespace()) ->
    {ok, [tag_name()]} |
    {error, Error::term()}.

-callback tags(Collection::collection(), Metric::metric(),
               Namespace::namespace()) ->
    {ok, [tag_name()]} |
    {error, Error::term()}.

-callback values(Collection::collection(), Namespace::namespace(),
                 Tag::tag_name()) ->
    {ok, [tag_value()]} |
    {error, Error::term()}.

-callback values(Collection::collection(), Metric::metric(),
                 Namespace::namespace(), Tag::tag_name()) ->
    {ok, [tag_value()]} |
    {error, Error::term()}.

-callback expand(Bucket::bucket(), [glob_metric()]) ->
    {ok, {bucket(), [metric()]}} |
    {error, Error::term()}.

-callback touch(touch_points()) ->
    ok |
    {error, Error::term()}.

-callback add(Collection::collection(),
              Metric::metric(),
              Bucket::bucket(),
              Key::key(),
              FirstSeen::timestamp()) ->
    {ok, MetricIdx::term()} | ok |
    {error, Error::term()}.

-callback add(Collection::collection(),
              Metric::metric(),
              Bucket::bucket(),
              Key::key(),
              FirstSeen::timestamp(),
              Tags::[{namespace(), tag_name(), tag_value()}]) ->
    {ok, MetricIdx::term()} | ok |
    {error, Error::term()}.

-callback update(Collection::collection(),
                 Metric::metric(),
                 Bucket::bucket(),
                 Key::key(),
                 Tags::[{namespace(), tag_name(), tag_value()}]) ->
    {ok, MetricIdx::term()} | ok |
    {error, Error::term()}.

-callback delete(Collection::collection(),
                 Metric::metric(),
                 Bucket::bucket(),
                 Key::key()) ->
    ok | {error, Error::term()}.

-callback delete(Collection::collection(),
                 Metric::metric(),
                 Bucket::bucket(),
                 Key::key(),
                 Tags::[{namespace(), tag_name(), tag_value()}]) ->
    ok | {error, Error::term()}.

%%====================================================================
%% API functions
%%====================================================================

%%--------------------------------------------------------------------
%% @doc
%% Initializes the Dalmatiner Query Engine indexer, this will hand
%% down to whatever indexing backend is used.
%% @end
%%--------------------------------------------------------------------

-spec init() -> ok | {error, Error::term()}.
init() ->
    Mod = idx_module(),
    Mod:init().

%%--------------------------------------------------------------------
%% @doc
%% Takes a lookup query and reutrns a list of all metric/bucket
%% paris that metch the lookup criteria.
%% @end
%%--------------------------------------------------------------------

-spec lookup(lqry(), start(), finish(), opts()) ->
                    {ok, [lookup_result()]} |
                    {error, Error::term()}.
lookup(Query, Start, Finish, Opts) ->
    Mod = idx_module(),
    Mod:lookup(Query, Start, Finish, Opts).

%%--------------------------------------------------------------------
%% @doc
%% Takes a lookup query and reutrns a list of all metric/bucket
%% paris that metch the lookup criteria with the values for the
%% provided group by fields (tags).
%% @end
%%--------------------------------------------------------------------

-spec lookup(lqry(), start(), finish(), [group_by_field()], opts()) ->
                    {ok, [{lookup_result(), [group_by_field()]}]} |
                    {error, Error::term()}.
lookup(Query, Start, Finish, GroupBy, Opts) ->
    Mod = idx_module(),
    Mod:lookup(Query, Start, Finish, GroupBy, Opts).

%%--------------------------------------------------------------------
%% @doc
%% Find all possible namespace, tag, value pairs for a query.
%% @end
%%--------------------------------------------------------------------

-spec lookup_tags(lqry()) ->
                         {ok, tags()} |
                         {error, Error::term()}.
lookup_tags(Query) ->
    Mod = idx_module(),
    Mod:lookup_tags(Query).

%%--------------------------------------------------------------------
%% @doc
%% Lists all collections.
%% @end
%%--------------------------------------------------------------------

-spec collections() ->
                         {ok, [collection()]} |
                         {error, Error::term()}.
collections() ->
    Mod = idx_module(),
    Mod:collections().

%%--------------------------------------------------------------------
%% @doc
%% Lists all metrics in a collections.
%% @end
%%--------------------------------------------------------------------

-spec metrics(Collection::collection()) ->
                     {ok, [metric()]} |
                     {error, Error::term()}.
metrics(Collection) ->
    Mod = idx_module(),
    Mod:metrics(Collection).


%%--------------------------------------------------------------------
%% @doc
%% Lists all metrics in a collections that match a given tag set.
%% @end
%%--------------------------------------------------------------------

-spec metrics(Collection::collection(), Where::where()) ->
                     {ok, [metric()]} |
                     {error, Error::term()}.
metrics(Collection, Where) ->
    Mod = idx_module(),
    Mod:metrics(Collection, Where).

%%--------------------------------------------------------------------
%% @doc
%% Returns a list of metric path suffixes of `Depth' that are prefixed
%% by the given probe `Prefix', which can also be empty.
%%
%% For example:
%% metrics(<<"collection">>, [], 1) -> [<<"base">>].
%% metrics(<<"collection">>, [<<"base">>], 1) -> [<<"cpu">>].
%% metrics(<<"collection">>, [], 2) -> [[<<"base">>,<<"cpu">>]].
%% @end
%%--------------------------------------------------------------------
-spec metrics(Collection::collection(), Prefix::metric(),
              Depth::pos_integer()) ->
                    {ok, [metric()]} |
                    {error, Error::term()}.
metrics(Collection, Prefix, Depth) ->
    Mod = idx_module(),
    Mod:metrics(Collection, Prefix, Depth).

%%--------------------------------------------------------------------
%% @doc
%% Lists all namespaces in a collection, across all metrics.
%% @end
%%--------------------------------------------------------------------

-spec namespaces(Collection::collection()) ->
                        {ok, [namespace()]} |
                        {error, Error::term()}.
namespaces(Collection) ->
    Mod = idx_module(),
    Mod:namespaces(Collection).

%%--------------------------------------------------------------------
%% @doc
%% Lists all namespaces for a metrics.
%% @end
%%--------------------------------------------------------------------

-spec namespaces(Collection::collection(), Metric::metric()) ->
                        {ok, [namespace()]} |
                        {error, Error::term()}.
namespaces(Collection, Metric) ->
    Mod = idx_module(),
    Mod:namespaces(Collection, Metric).

%%--------------------------------------------------------------------
%% @doc
%% Lists all tags for a namespaces across all metrics in a collection.
%% @end
%%--------------------------------------------------------------------

-spec tags(Collection::collection(), Namesplace::namespace()) ->
                  {ok, [tag_name()]} |
                  {error, Error::term()}.
tags(Collection, Namespace) ->
    Mod = idx_module(),
    Mod:tags(Collection, Namespace).

%%--------------------------------------------------------------------
%% @doc
%% Lists all tags for a namespaces metrics.
%% @end
%%--------------------------------------------------------------------

-spec tags(Collection::collection(), Metric::metric(),
           Namesplace::namespace()) ->
                  {ok, [tag_name()]} |
                  {error, Error::term()}.
tags(Collection, Metric, Namespace) ->
    Mod = idx_module(),
    Mod:tags(Collection, Metric, Namespace).

%%--------------------------------------------------------------------
%% @doc
%% Lists all the possible values for a tag across all metrics in a
%% collection
%% @end
%%--------------------------------------------------------------------

-spec values(Collection::collection(), Namespace::namespace(),
             Tag::tag_name()) ->
                    {ok, [tag_value()]} |
                    {error, Error::term()}.
values(Collection, Namespace, Tag) ->
    Mod = idx_module(),
    Mod:values(Collection, Namespace, Tag).

%%--------------------------------------------------------------------
%% @doc
%% Lists all the possible values for a tag
%% @end
%%--------------------------------------------------------------------

-spec values(Collection::collection(), Metric::metric(),
             Namesplace::namespace(), Tag::tag_name()) ->
                    {ok, [tag_value()]} |
                    {error, Error::term()}.
values(Collection, Metric, Namespace, Tag) ->
    Mod = idx_module(),
    Mod:values(Collection, Metric, Namespace, Tag).

%%--------------------------------------------------------------------
%% @doc
%% Expands a glob into all matching metrics for a given bucket.
%% WARNING: This might go away!
%% @end
%%--------------------------------------------------------------------

-spec expand(bucket(), [glob_metric()]) ->
                    {ok, {bucket(), [metric()]}} |
                    {error, Error::term()}.
expand(B, Gs) ->
    Mod = idx_module(),
    Mod:expand(B, Gs).

%%--------------------------------------------------------------------
%% @doc
%% Sets the last seen value for a metric overwriting the current
%% value.
%% @end
%%--------------------------------------------------------------------

-spec touch(touch_points()) ->
    ok |
    {error, Error::term()}.

touch(Data) ->
    Mod = idx_module(),
    Mod:touch(Data).

%%--------------------------------------------------------------------
%% @doc
%% Links a collection/metric to a bucket and key. Returns whatever
%% identifyer the colleciton/metric has if any. This MAY either return
%% {ok, ID} or optinally ok, if ok is returned it MUST only be done
%% if the metric was already present in the index store. Returning
%% {ok, ID} is ALWAYS acceptable. A consumer of this API MAY assume
%% that if ok is returned the related tags are already in the store
%% as well.<br/>
%% If the metric doesn't exist last seen should be set to
%% infinity.<br/>
%% A First Seen timestamp might be provided. If it is and
%% a new metric is created the first seen value of this metric should
%% be set to the value. If it is provided and the metricdoes already
%% exist the last seen should be set to the maximum of the provided
%% value and the current last seen.
%% @end
%%--------------------------------------------------------------------

-spec add(Collection::collection(),
          Metric::metric(),
          Bucket::bucket(),
          Key::key(),
          FistSeen::timestamp()) ->
                 {ok, MetricIdx::term()} |
                 ok |
                 {error, Error::term()}.

add(Collection, Metric, Bucket, Key, Timestamp) ->
    Mod = idx_module(),
    Mod:add(Collection, Metric, Bucket, Key, Timestamp).

%%--------------------------------------------------------------------
%% @doc
%% Adds one or more metrics tag pairs to a metric. This
%% function MUST not change existing tags, or add tags to an existing
%% metric IF add/4 returned ok. It MAY add additional tags if add/4
%% returned {ok, ID} despite the metric being present.<br/>
%% If the metric doesn't exist last seen should be set to
%% infinity.<br/>
%% A First Seen timestamp might be provided. If it is and
%% a new metric is created the first seen value of this metric should
%% be set to the value. If it is provided and the metricdoes already
%% exist the last seen should be set to the maximum of the provided
%% value and the current last seen.
%% @end
%%--------------------------------------------------------------------

-spec add(Collection::collection(),
          Metric::metric(),
          Bucket::bucket(),
          Key::key(),
          FistSeen::timestamp(),
          Tags::[{namespace(), tag_name(), tag_value()}]) ->
                 {ok, MetricIdx::term()} |
                 ok |
                 {error, Error::term()}.

add(Collection, Metric, Bucket, Key, Timestamp, Tags) ->
    Mod = idx_module(),
    Mod:add(Collection, Metric, Bucket, Key, Timestamp, Tags).

%%--------------------------------------------------------------------
%% @doc
%% Updates values of a metric, this behaves equivalent to add/5 if
%% the metric was not yet known to the index store, if however it was
%% known it MUST add new tags and MUST update existing tags. This is
%% meant to be used with metadata tags as described in the metrics2.0
%% specification.<br/>
%% If the metric doesn't exist last seen should be set to
%% infinity.<br/>
%% A First Seen timestamp might be provided. If it is and
%% a new metric is created the first seen value of this metric should
%% be set to the value. If it is provided and the metricdoes already
%% exist the last seen should be set to the maximum of the provided
%% value and the current last seen.
%% @end
%%--------------------------------------------------------------------

-spec update(Collection::collection(),
             Metric::metric(),
             Bucket::bucket(),
             Key::key(),
             Tags::[{namespace(), tag_name(), tag_value()}]) ->
                    {ok, MetricIdx::term()} |
                    ok |
                    {error, Error::term()}.

update(Collection, Metric, Bucket, Key, Tags) ->
    Mod = idx_module(),
    Mod:update(Collection, Metric, Bucket, Key, Tags).

%%--------------------------------------------------------------------
%% @doc
%% Deletes a Collection/Metric pair and all it's tags.
%% @end
%%--------------------------------------------------------------------

-spec delete(Collection::collection(),
             Metric::metric(),
             Bucket::bucket(),
             Key::key()) ->
                    ok |
                    {error, Error::term()}.

delete(Collection, Metric, Bucket, Key) ->
    Mod = idx_module(),
    Mod:delete(Collection, Metric, Bucket, Key).

%%--------------------------------------------------------------------
%% @doc
%% Deletes one or more tag pairs from a Metric. This funciton can
%% call delete/6 multiple times or use a more optimized method. This
%% MUST only be used with metric2.0 like metadata tags that do not
%% change metric identity!
%% @end
%%--------------------------------------------------------------------
-spec delete(Collection::collection(),
             Metric::metric(),
             Bucket::bucket(),
             Key::key(),
             Tags::[{namespace(), tag_name()}]) ->
                    ok |
                    {error, Error::term()}.

delete(Collection, Metric, Bucket, Key, Tags) ->
    Mod = idx_module(),
    Mod:delete(Collection, Metric, Bucket, Key, Tags).

%%====================================================================
%% Internal functions
%%====================================================================
idx_module() ->
    application:get_env(dqe_idx, lookup_module, dqe_idx_ddb).
