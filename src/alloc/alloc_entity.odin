package alloc_utils
import "base:intrinsics"

/* TODO: If you were making a game you might want something like this:
  m: map[int]Entity
But if you add new entities, you would have to copy the entities,
so then you would be looking at old memory, and you would free it
at the end of the frame?

Alternatively you could do:
  m: map[int]^Entity
Then you wouldn't have to move the entities, but you would
be jumping through an extra pointer..
*/
