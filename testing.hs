-- Bare bones testing framework. TODO: use a real testing framework!
module Testing(printCompare,runAll,runTestParseThen,runTest,runTestAllowAmb) where

import Control.Exception
import System.Exit
import System.IO
import Chart

seeAll :: Bool
seeAll = False

printCompare :: (Show t, Show a, Eq a) => String -> [t] -> a -> a -> IO Bool
printCompare tag input actual expect =
  if (actual == expect)
  then do putStr ("PASS: " ++ tag ++ ": " ++ show input ++ "\n"); return True
  else do putStr ("FAIL: " ++ tag ++ ": " ++ show input ++ "\n--Expect = " ++ show expect ++ "\n--Actual = " ++ show actual ++ "\n"); return False

runAll :: [IO Bool] -> IO ()
runAll xs =  do
  results <- sequence (map wrap xs)
  let isPass r = case r of Just True -> True ; _ -> False
  let isFail r = case r of Just False -> True ; _ -> False
  let isException r = case r of Nothing -> True ; _ -> False
  let p = length (filter isPass results)
  let f = length (filter isFail results)
  let e = length (filter isException results)
  hPutStr (if seeAll then stderr else stdout) (
    "#pass = " ++ show p ++ ", " ++
    "#fail = " ++ show f ++ ", " ++
    "#exception = " ++ show e ++ "\n")
  if (f+e > 0) then exitFailure else exitSuccess


wrap :: IO a -> IO (Maybe a)
wrap io = handle (\e -> do
  putStr ("EXCEPTION: " ++ show (e::SomeException) ++ "\n")
  return Nothing) (fmap Just io)


runTestParseThen ::
  (Eq b, Show a, Show b, Show t) =>
  Config -> (Parsing a -> b) -> String -> Lang t (Gram a) ->
  ([t] -> b -> IO Bool,
   [t] -> b -> IO Bool)
runTestParseThen config f tag lang = (go False, go True)
  where
    go seePartials input expect = do
      () <- if seePartials
            then do
              putStrLn ("Running (" ++ tag ++ ") " ++ show input)
              _ <- sequence (map print partials)
              putStrLn ("Effort = " ++ show effort)
              putStrLn ("Outcome = " ++ show outcome)
            else return ()
      printCompare tag input actual expect
      where
        Parsing effort partials outcome = parsing
        actual = f parsing
        parsing = doParseConfig config lang input

runTest :: (Show a, Show t, Eq a) => String -> Lang t (Gram a)
        -> ([t] -> Outcome a -> IO Bool, [t] -> Outcome a -> IO Bool)
runTest = runTestParseThen rejectAmb (\(Parsing _ _ o) -> o)


runTestAllowAmb :: (Show a, Show t, Eq a) => String -> Lang t (Gram a)
        -> ([t] -> Outcome a -> IO Bool, [t] -> Outcome a -> IO Bool)
runTestAllowAmb = runTestParseThen allowAmb (\(Parsing _ _ o) -> o)

