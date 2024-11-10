using { /Verse.org/Assets }

cosmetic_data<public> := interface:
    GetName<public>()<transacts> : string
    GetIndex<public>()<transacts> : int
    GetThumbnail<public>()<transacts> : texture

aura_cosmetic_data<public> := class<computes>(cosmetic_data):
    Name<public> : string 
    Index<public> : int
    Thumbnail<public> : texture

    GetName<override>()<transacts> : string = Name
    GetIndex<override>()<transacts> : int = Index
    GetThumbnail<override>()<transacts> : texture = Thumbnail