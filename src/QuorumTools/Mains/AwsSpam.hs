{-# LANGUAGE OverloadedStrings #-}

module QuorumTools.Mains.AwsSpam where

import           Control.Monad.Reader (runReaderT)
import           Control.RateLimit    (RateLimit)
import           Data.Bool            (bool)
import qualified Data.Map.Strict      as Map
import           Data.Time.Units      (Millisecond)
import           Turtle

import           QuorumTools.Aws
import           QuorumTools.Client   (loadNode, perSecond, spamGeth)
import           QuorumTools.Cluster
import           QuorumTools.Spam
import           QuorumTools.Types

data SpamConfig = SpamConfig { rateLimit   :: RateLimit Millisecond
                             , clusterType :: AwsClusterType
                             , contract    :: Maybe Text
                             , privateFor  :: Maybe Text
                             }

cliParser :: Parser SpamConfig
cliParser = SpamConfig
  <$> fmap perSecond (optInteger "rps"  'r' "The number of requests per second")
  <*> fmap (bool SingleRegion MultiRegion)
           (switch  "multi-region" 'g' "Whether the cluster is multi-region")
  <*> optional contractP
  <*> optional privateForP

mkSingletonEnv :: MonadIO m => AwsClusterType -> GethId -> m ClusterEnv
mkSingletonEnv cType gid = do
    key <- readAccountKey dataDir gid
    subnets <- readNumSubnetsFromHomedir
    return $ mkClusterEnv (mkIp subnets) (const dataDir) (Map.singleton gid key)

  where
    dataDir = DataDir "/datadir"

    mkIp numSubnets = case cType of
      SingleRegion -> internalAwsIp numSubnets
      MultiRegion  -> const dockerHostIp

readNumSubnetsFromHomedir :: MonadIO m => m Int
readNumSubnetsFromHomedir = liftIO $ read <$> readFile "/home/ubuntu/num-subnets"

readGidFromHomedir :: IO GethId
readGidFromHomedir = GethId . read <$> readFile "/home/ubuntu/node-id"

awsSpamMain :: IO ()
awsSpamMain = awsSpam =<< parseConfig
  where
    parseConfig = options "Spams the local node with public transactions"
                          cliParser

awsSpam :: SpamConfig -> IO ()
awsSpam config = do
  gid <- readGidFromHomedir
  let benchTx = processContractArgs (contract config) (privateFor config)
  cEnv <- mkSingletonEnv (clusterType config) gid
  geth <- runReaderT (loadNode gid) cEnv
  spamGeth benchTx geth (rateLimit config)
