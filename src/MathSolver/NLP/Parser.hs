{-# LANGUAGE OverloadedStrings #-}

module MathSolver.NLP.Parser where

import Data.Either
import Data.Text (Text)
import qualified Data.Text as T
import qualified NLP.Corpora.Brown as B
import NLP.Extraction.Parsec
import NLP.POS
import NLP.Types
import NLP.Types.Tags
import NLP.Types.Tree
import Text.Parsec.Prim ( (<|>), try)
import qualified Text.Parsec.Combinator as PC
import MathSolver.Types
import MathSolver.NLP.WordNum


{--------------------------------------------------------------------------------------------------}
{---                                        Sentence Type                                       ---}
{--------------------------------------------------------------------------------------------------}

data SentenceType = Evt | Qst
    deriving (Show, Eq)

tsNull :: Tag t => TaggedSentence t -> Bool
tsNull (TaggedSent []) = True
tsNull _ = False

tsType :: Tag tag => TaggedSentence tag -> SentenceType
tsType s
    | punctuation == "?"  = Qst
    | otherwise           = Evt
    where
        punctuation = (showTok . posToken . last . unTS) s

isEvt :: Tag tag => TaggedSentence tag -> Bool
isEvt s = tsType s == Evt

isQst :: Tag tag => TaggedSentence tag -> Bool
isQst s = tsType s == Qst


{--------------------------------------------------------------------------------------------------}
{---                                       Problem Parser                                       ---}
{--------------------------------------------------------------------------------------------------}

getQst :: Tag tag => [TaggedSentence tag] -> TaggedSentence tag
getQst [] = TaggedSent []
getQst ss = last ss

getEvs :: Tag tag => [TaggedSentence tag] -> [TaggedSentence tag]
getEvs [] = [TaggedSent []]
getEvs ss = init ss


getProblem :: Tag tag => [TaggedSentence tag] -> (TaggedSentence tag, [TaggedSentence tag])
getProblem p = (getQst p, getEvs p)


parseQst :: Tag tag => TaggedSentence tag -> QuestionType
parseQst = undefined

parseEvts :: Tag tag => [TaggedSentence tag] -> [Event]
parseEvts = map parseEvt

parseEvt :: Tag tag => TaggedSentence tag -> Event
parseEvt = undefined

parseEvtOwner :: Tag tag => TaggedSentence tag -> Name
parseEvtOwner s = undefined

parseQstOwner :: Tag tag => TaggedSentence tag -> Name
parseQstOwner s = undefined


{-
tagger <- brownTagger
tagged = tag tagger "Lucy bought 12 packs of cookies and 16 packs of noodles."
tagFull = tag tagger "Lucy bought 12 packs of cookies and 16 packs of noodles. Jane gave her two more. How many does she have now?"
-}


{---
Look at the first event for action type. If it's not in the ADD/REMOVE group, treat it as a SET
-}