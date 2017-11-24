module MathSolver.Calc.Solver where

import Data.List
import Data.Maybe

import MathSolver.Types


ownerNames :: State -> [Name]
ownerNames = map name

items :: Inventory -> [Item]
items = map fst

{--------------------------------------------------------------------------------------------------}
{---                                        ADJUST STATE                                        ---}
{--------------------------------------------------------------------------------------------------}

setItem :: Item -> Amount -> Inventory -> Inventory
setItem item amount inv
    | amount == 0 && hasItem  = is ++ js
    | amount == 0             = inv
    | amount /= 0 && hasItem  = (item, amount) : is ++ js
    | otherwise               = (item, amount) : inv
    where
        hasItem = item `elem` items inv
        (is, _:js) = break (\(i,_) -> i == item) inv

addItem :: Item -> Amount -> Inventory -> Inventory
addItem item amount inv
    | not hasItem && amount == 0  = inv
    | not hasItem                 = (item, amount) : inv
    | total == 0                  = is ++ js
    | total /= 0                  = (item, total) : is ++ js
    | otherwise                   = inv
    where
        hasItem = item `elem` items inv
        (is, i:js) = break (\(i,_) -> i == item) inv
        total = snd i + amount

set :: Name -> Item -> Amount -> State -> State
set owner item amount state
    | null item                      = state
    | amount == 0 && not ownerKnown  = (Owner owner []) : state
    | amount /= 0 && not ownerKnown  = (Owner owner [(item, amount)]) : state
    | amount == 0                    = o : xs ++ ys
    | otherwise                      = (Owner n (setItem item amount inv)) : xs ++ ys
    where
        ownerKnown = owner `elem` ownerNames state
        (xs, o@(Owner n inv):ys) = break (\o -> name o == owner) state

add :: Name -> Item -> Amount -> State -> State
add owner item amount state
    | null item                      = state
    | amount == 0 && not ownerKnown  = (Owner owner []) : state
    | amount /= 0 && not ownerKnown  = (Owner owner [(item, amount)]) : state
    | amount == 0                    = o : xs ++ ys
    | otherwise                      = (Owner n (addItem item amount inv)) : xs ++ ys
    where
        ownerKnown = owner `elem` ownerNames state
        (xs, o@(Owner n inv):ys) = break (\o -> name o == owner) state

remove :: Name -> Item -> Amount -> State -> State
remove owner item amount = add owner item (-amount)

empty :: Name -> Item -> State -> State
empty owner item = set owner item 0

reset :: Name -> State -> State
reset owner state
    | owner `elem` ownerNames state = (Owner owner []) : filter (\o -> name o /= owner) state
    | otherwise                     = state

give :: Name -> Item -> Amount -> Name -> State -> State
give owner item amount target state
    | owner == target  = state
    | otherwise        = remove owner item amount $ add target item amount state

takeFrom :: Name -> Item -> Amount -> Name -> State -> State
takeFrom owner item amount target state
    | owner == target  = state
    | otherwise        = add owner item amount $ remove target item amount state

{--------------------------------------------------------------------------------------------------}
{---                                         RUN EVENTS                                         ---}
{--------------------------------------------------------------------------------------------------}

-- Solves a question and gives an answer
solve :: Problem -> Answer
solve (Problem question events) = ask question $ run events
  where
    ask :: Question -> State -> Answer
    ask (Question (Quantity subject) item) state = Answer (Quantity subject) result item
        where result = finalQuantity subject item state

    ask (Question (Compare subject target) item) state
        | subject == target  = Answer (Quantity subject) subjQuantity item
        | otherwise          = Answer (Compare subject target) diff item
        where
            subjQuantity = finalQuantity subject item state
            diff = subjQuantity - finalQuantity target item state 

    ask (Question (Combine subj1 subj2) item) state
        | subj1 == subj2  = Answer (Quantity subj1) subjQuantity item
        | otherwise       = Answer (Combine subj1 subj2) total item
        where
            subjQuantity = finalQuantity subj1 item state
            total = subjQuantity + finalQuantity subj2 item state

    ask (Question CombineAll item) state = Answer CombineAll total item
      where
        hasItem = item `elem` (map fst $ concatMap inventory state)
        total
            | hasItem    = sum [amount | (item,amount) <- concatMap inventory state]
            | otherwise  = sum $ map snd $ concatMap inventory state

    -- If the answer is 0, the term is probably generalized, assuming it's not a trick question
    finalQuantity :: Name -> Item -> State -> Amount
    finalQuantity name item state
        | owner == NoOne  = 0
        | hasItem         = hasAmount item inv
        | otherwise       = hasTotal inv
        where
            owner = findOwner name state
            inv = inventory owner
            hasItem = item `elem` items inv

    -- If no info given, default to 0
    hasAmount :: Item -> Inventory -> Amount
    hasAmount item inv = fromMaybe 0 (lookup item inv)

    -- Calculates total number of items someone has
    hasTotal :: Inventory -> Amount
    hasTotal inv = sum $ map snd inv

    -- Finds the Owner given a name
    findOwner :: Name -> State -> Owner
    findOwner n state
        | null owner  = NoOne
        | otherwise   = head owner
        where
            owner = dropWhile (\o -> name o /= n) state

-- Runs all events on an initial empty problem state
run :: [Event] -> State
run = foldl' eval []

-- Evaluates a single event on the current problem state
eval :: State -> Event -> State
eval state (Event owner (Set amount item)) = set owner item amount state
eval state (Event owner (Add amount item)) = add owner item amount state
eval state (Event owner (Remove amount item)) = remove owner item amount state
eval state (Event owner (Empty item)) = empty owner item state
eval state (Event owner Reset) = reset owner state
eval state (Event owner (Give amount item target)) = give owner item amount target state
eval state (Event owner (TakeFrom amount item target)) = takeFrom owner item amount target state

{--------------------------------------------------------------------------------------------------}
{---                                        TEST STATES                                         ---}
{--------------------------------------------------------------------------------------------------}

state1 = [Owner "Tom" [("apples",5), ("bananas",10)]]
state2 = [Owner "Jane" [("apples",10)], Owner "Tom" [("apples",5),("bananas",10)]]

-- Tom grabs ten apples from a tree. He gives two to Jane.
-- Jane then takes another three from Tom and one from the tree.
events1 = [Event "Tom" (Add 10 "apples"), Event "Tom" (Give 2 "apples" "Jane"),
           Event "Jane" (TakeFrom 3 "apples" "Tom"), Event "Jane" (Add 1 "apples")]

quantity1 = solve (Problem (Question (Quantity "Tom") "apples") events1)
quantity2 = solve (Problem (Question (Quantity "Jane") "apples") events1)

compare1 = solve (Problem (Question (Compare "Tom" "Jane") "apples") events1)
compare2 = solve (Problem (Question (Compare "Jane" "Tom") "apples") events1)

combine = solve (Problem (Question (Combine "Jane" "Tom") "apples") events1)

combineAll = solve (Problem (Question CombineAll "apples") events1)
