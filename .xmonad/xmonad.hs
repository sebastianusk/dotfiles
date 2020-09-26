import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Util.Run(spawnPipe)
import XMonad.Util.EZConfig(additionalKeys)
import System.IO


main = xmonad defaultConfig
        { layoutHook = avoidStruts $ layoutHook defaultConfig
        , terminal = "st"
        , modMask = mod4ask
        }
