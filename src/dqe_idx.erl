-module(dqe_idx).

%% API exports
-export([]).
-export_type([where/0, query/0]).

-type where() :: {binary(), binary()} |
                 {'and', where(), where()} |
                 {'or', where(), where()}.
-type query() :: dql:bm() | 
                 {binary(), [binary()], where()}.

-callback lookup(query()) -> {ok, [dql:bm()]}.
