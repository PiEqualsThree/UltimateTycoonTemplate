using { /Verse.org/Assets }

cosmetic_data<public> := interface:
    GetName<public>()<transacts> : string
    GetID<public>()<transacts> : int
    GetImage<public>()<transacts> : texture

aura_cosmetic_data<public> := class<computes>(cosmetic_data):
    ID<public> : int
    Name<public> : string 
    Image<public> : texture

    GetID<override>()<transacts> : int = ID
    GetName<override>()<transacts> : string = Name
    GetImage<override>()<transacts> : texture = Image

vehicle_cosmetic_data<public> := class<computes>(cosmetic_data):
    ID<public> : int
    Name<public> : string 
    Image<public> : texture

    GetID<override>()<transacts> : int = ID
    GetName<override>()<transacts> : string = Name
    GetImage<override>()<transacts> : texture = Image

vfx_cosmetic_data<public> := class<computes>(cosmetic_data):
    ID<public> : int
    Name<public> : string 
    Image<public> : texture

    GetID<override>()<transacts> : int = ID
    GetName<override>()<transacts> : string = Name
    GetImage<override>()<transacts> : texture = Image