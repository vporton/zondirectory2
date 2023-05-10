let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.8.8-20230505/package-set.dhall sha256:a080991699e6d96dd2213e81085ec4ade973c94df85238de88bc7644a542de5d
let Package =
    { name : Text, version : Text, repo : Text, dependencies : List Text }

let
  -- This is where you can add your own packages to the package-set
  additions =
    [
      { name = "stable-rbtree"
      , repo = "https://github.com/canscale/StableRBTree"
      , version = "v0.6.1"
      , dependencies = [ "base" ]
      },
      { name = "StableBuffer"
      , repo = "https://github.com/canscale/StableBuffer"
      , version = "v0.2.0"
      , dependencies = [ "base" ]
      },
      { name = "stable-buffer"
      , repo = "https://github.com/canscale/StableBuffer"
      , version = "v0.2.0"
      , dependencies = [ "base" ]
      },
      { name = "btree"
      , repo = "https://github.com/canscale/StableHeapBTreeMap"
      , version = "v0.3.1"
      , dependencies = [ "base" ]
      },
      { name = "candb"
      , repo = "git@github.com:canscale/CanDB.git"
      , version = "beta"
      , dependencies = [ "base" ]
      },
      { name = "icrc1"
      , repo = "git@github.com:NatLabs/icrc1"
      , version = "0.0.1"
      , dependencies = [ "base", "itertools" ]
      },
      { name = "itertools"
      , repo = "git@github.com:NatLabs/itertools"
      , version = "main"
      , dependencies = [ "base" ]
      },
      { name = "StableTrieMap"
      , repo = "git@github.com:NatLabs/StableTrieMap"
      , version = "main"
      , dependencies = [ "base" ]
      },
      { name = "array"
      , version = "v0.2.1"
      , repo = "https://github.com/aviate-labs/array.mo"
      , dependencies = [ "base" ] : List Text
      },
    ] : List Package

let
  {- This is where you can override existing packages in the package-set

     For example, if you wanted to use version `v2.0.0` of the foo library:
     let overrides = [
         { name = "foo"
         , version = "v2.0.0"
         , repo = "https://github.com/bar/foo"
         , dependencies = [] : List Text
         }
     ]
  -}
  overrides =
    [] : List Package

in  upstream # additions # overrides