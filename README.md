# math-solver
The goal of the project is to be able to parse, solve, and answer (in natural language) basic math word problems. The program will be given a math problem in paragraph form that involves addition and subtraction. We might add more operations later. The system then parses the question it’s asked to solve to determine the problem type and what information is needed. The system will then preprocess the problem into a problem that is easier to parse directly, and it’ll remove all irrelevant data. Next, the system will parse the rest of the problem into a list of events. After parsing, each event’s action will be converted to its category. The events will then be evaluated, and the system will keep track of the state throughout the evaluation process. Then, the question will be applied to the final state to calculate an answer. Finally, the answer will be translated back into a natural language response.