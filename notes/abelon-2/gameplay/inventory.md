- Inventory starts in the top left
- Submenus open to the right and scroll down if there are more than 8 options
- Description of the hovered menu item appears in bottom right for non-endpoints
- Additional info box appears in bottom left if the hovered item is complex
- Upon selecting a menu item, open a submenu unless it's an endpoint

A confirmation box appears in the middle to confirm changes.

Items ->
    <list of items> -> (hover: name, picture, and description)
        Use ->
            (centered) There's nothing to be done with this right now.
            *OR*
            <launch scene>
        Present ->
            (centered) No one nearby seems to notice.
            *OR*
            <launch scene>
        Discard -> (greyed out for non-discardables)
            (centered) Discard <item>? It will be gone forever. Yes/No

Party ->
    <list of party members> ->
        Attributes (hover: sprite, portrait, attributes, status, equipment)
        Skills ->
            Attacks ->
                <list of attacks w tree icons> (hover: skill description)
            Spells ->
                <list of spells w tree icons> (hover: skill description)
            Utility ->
                <list of utilities w tree icons> (hover: skill description)
            Assists ->
                <list of assists w tree icons> (hover: skill description)
        Learn (<# skill points>) ->
            <tree 1 name> ->
                <list of skills w skill icon and requirement tree icons/numbers,
                ordered by requirements> -> (hover: skill description)
                    Learn ->
                        (centered) Spend one skill point to learn <skill name>?
                        Yes/No
                        *OR*
                        (centered) No skill point available to learn this skill
                        *OR*
                        (centered) Requirements not met to learn this skill:
                        <list requirements>
            <tree 2 name> ->
                ~
            <tree 3 name> ->
                ~
Settings ->
    Video ->
        Coming Soon!
    Volume ->
        Music -> (render a star next to the current volume setting)
            Off
            Low
            Medium
            High
        Sound Effects ->
            ~
        Text Effects ->
            ~
    Difficulty -> (render a star next to the current difficulty setting)
        Normal ->
            (centered) Lower the difficulty to <selection>? Difficulty can be
            lowered but not raised. Yes/No
            *OR*
            (centered) Difficulty can only be lowered, not raised.
            *OR*
            (centered) This is the current difficulty setting.
        Adept ->
            ~
        Master
    Formulas (hover: combat formulas)
Quit ->
    Save and Quit ->
        (centered) Save current progress and close the game? Yes/No
    Restart Part 1/2 ->
        (centered) Are you SURE you want to restart Part <current part>?
        You will lose ALL progress made during Part <current part>. Yes/No
