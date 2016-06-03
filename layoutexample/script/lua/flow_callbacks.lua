ProjectFlowCallbacks = ProjectFlowCallbacks or {}

-- Example custom project flow node callback. Prints a message.
-- The parameter t contains the node inputs, and node outputs can 
-- be set on t. See documentation for details.
function ProjectFlowCallbacks.example(t)
	local message = t.text or "" -- note all custom node input variable names are converted to lower case
	print("Example Node Message: " .. message)
end
