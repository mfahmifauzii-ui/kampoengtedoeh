--!strict
-- Starts the Q-2 feature gate on the client (prompts). The HUD buttons call FeatureClient.GateHud from their own controllers.
-- Client only; the server still checks every gated remote and prompt (FeatureGate.Check).

local FeatureClient = require(script.Parent.FeatureClient)

FeatureClient.StartPrompts()
