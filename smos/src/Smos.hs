{-# LANGUAGE RecordWildCards #-}

module Smos
    ( smos
    , module Smos.Config
    ) where

import Import

import Data.Time

import System.Exit

import Brick.Main as B

import Smos.Data

import Smos.App
import Smos.Config
import Smos.OptParse
import Smos.Types

smos :: SmosConfig -> IO ()
smos sc@SmosConfig {..} = do
    Instructions p Settings <- getInstructions sc
    errOrSF <- readSmosFile p
    startF <-
        case errOrSF of
            Nothing -> pure Nothing
            Just (Left err) ->
                die $
                unlines
                    [ "Failed to read smos file"
                    , fromAbsFile p
                    , "could not parse it:"
                    , show err
                    ]
            Just (Right sf) -> pure $ Just sf
    tz <- getCurrentTimeZone
    let s = initState p startF tz
    s' <- defaultMain (mkSmosApp sc) s
    let sf' = rebuildEditorCursor $ smosStateCursor s'
    when (smosStateStartSmosFile s' /= Just sf') $ writeSmosFile (smosStateFilePath s') sf'
