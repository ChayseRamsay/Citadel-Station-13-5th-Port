//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:32

//TODO: Make these simple_animals
#define isfacehugger(A) (istype(A, /obj/item/clothing/mask/facehugger))
var/const/MIN_IMPREGNATION_TIME = 300 //time it takes to impregnate someone
var/const/MAX_IMPREGNATION_TIME = 400

var/const/MIN_ACTIVE_TIME = 100 //time between being dropped and going idle
var/const/MAX_ACTIVE_TIME = 200

/obj/item/clothing/mask/facehugger
	name = "alien"
	desc = "It has some sort of a tube at the end of its tail."
	icon = 'icons/mob/alien.dmi'
	icon_state = "facehugger"
	item_state = "facehugger"
	w_class = 1 //note: can be picked up by aliens unlike most other items of w_class below 4
	flags = MASKINTERNALS
	throw_range = 2
	tint = 3
	flags_cover = MASKCOVERSEYES | MASKCOVERSMOUTH
	layer = MOB_LAYER

	var/stat = CONSCIOUS //UNCONSCIOUS is the idle state in this case

	var/sterile = 0
	var/real = 1 //0 for the toy, 1 for real. Sure I could istype, but fuck that.
	var/strength = 5

	var/attached = 0

/obj/item/clothing/mask/facehugger/attack_alien(mob/user) //can be picked up by aliens
	if(isalienadult(user))
		var/mob/living/carbon/alien/humanoid/A = user
		if(A.crawling)
			return
	if(isalienravager(user))
		return
	attack_hand(user)
	return

/obj/item/clothing/mask/facehugger/attack_hand(mob/user)
	if((stat == CONSCIOUS && !sterile) && !isalien(user))
		if(Attach(user))
			return
	..()

/obj/item/clothing/mask/facehugger/attack(mob/living/M, mob/user)
	..()
	user.unEquip(src)
	Attach(M)

/obj/item/clothing/mask/facehugger/examine(mob/user)
	..()
	if(!real)//So that giant red text about probisci doesn't show up.
		return
	switch(stat)
		if(DEAD,UNCONSCIOUS)
			user << "<span class='boldannounce'>[src] is not moving.</span>"
		if(CONSCIOUS)
			user << "<span class='boldannounce'>[src] seems to be active!</span>"
	if (sterile)
		user << "<span class='boldannounce'>It looks like the proboscis has been removed.</span>"

/obj/item/clothing/mask/facehugger/attackby(obj/item/O,mob/m, params)
	if(O.force)
		Die()
	return

/obj/item/clothing/mask/facehugger/bullet_act(obj/item/projectile/P)
	if(P.damage)
		Die()
	return

/obj/item/clothing/mask/facehugger/temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	if(exposed_temperature > 300)
		Die()
	return

/obj/item/clothing/mask/facehugger/equipped(mob/M)
	Attach(M)

/obj/item/clothing/mask/facehugger/Crossed(atom/target)
	HasProximity(target)
	return

/obj/item/clothing/mask/facehugger/on_found(mob/finder)
	if(stat == CONSCIOUS)
		return HasProximity(finder)
	return 0

/obj/item/clothing/mask/facehugger/HasProximity(atom/movable/AM as mob|obj)
	if(CanHug(AM) && Adjacent(AM))
		return Attach(AM)
	return 0

/obj/item/clothing/mask/facehugger/throw_at(atom/target, range, speed, mob/thrower, spin)
	if(!..())
		return
	if(stat == CONSCIOUS)
		icon_state = "[initial(icon_state)]_thrown"
		spawn(15)
			if(icon_state == "[initial(icon_state)]_thrown")
				icon_state = "[initial(icon_state)]"

/obj/item/clothing/mask/facehugger/throw_impact(atom/hit_atom)
	..()
	if(stat == CONSCIOUS)
		icon_state = "[initial(icon_state)]"
		Attach(hit_atom)

/obj/item/clothing/mask/facehugger/proc/Attach(mob/living/M)
	if(!isliving(M))
		return 0
	if((!iscorgi(M) && !iscarbon(M)) || isalien(M))
		return 0
	if(attached)
		return 0
	else
		attached++
		spawn(MAX_IMPREGNATION_TIME)
			attached = 0
	if(M.getorgan(/obj/item/organ/internal/alien/hivenode))
		return 0
	if(M.getorgan(/obj/item/organ/internal/body_egg/alien_embryo))
		return 0
	if(loc == M)
		return 0
	if(stat != CONSCIOUS)
		return 0
	if(!sterile) M.take_organ_damage(strength,0) //done here so that even borgs and humans in helmets take damage
	M.visible_message("<span class='danger'>[src] leaps at [M]'s face!</span>", \
						"<span class='userdanger'>[src] leaps at [M]'s face!</span>")
	src.Move(M.loc)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		var/obj/item/clothing/helm = H.head
		if(H.head && istype(helm, /obj/item/clothing/head/helmet/space/hardsuit))
			var/obj/item/clothing/suit/space/hardsuit/hsuit = H.wear_suit
			hsuit.ToggleHelmet()
			H.visible_message("<span class='danger'>[src] tears [helm] off of [H]!</span>", \
							"<span class='userdanger'>[src] tears [helm] off of [H]!</span>")
			GoIdle()
			return 0
		else if(H.head && (helm.flags & NODROP))
			return 0
		else if(H.head && H.is_mouth_covered(head_only = 1))
			H.unEquip(helm)
			H.visible_message("<span class='danger'>[src] tears [helm] off of [H]!</span>", \
							"<span class='userdanger'>[src] tears [helm] off of [H]!</span>")
			GoIdle()
			return 0

	if(iscarbon(M))
		var/mob/living/carbon/target = M
		if(target.wear_mask)
			var/obj/item/clothing/W = target.wear_mask
			if(W.flags & NODROP)
				return 0
			target.unEquip(W)
			target.visible_message("<span class='danger'>[src] tears [W] off of [target]'s face!</span>", \
									"<span class='userdanger'>[src] tears [W] off of [target]'s face!</span>")

		src.loc = target
		target.equip_to_slot(src, slot_wear_mask,,0)
		if(!sterile)
			M.Paralyse(MAX_IMPREGNATION_TIME/12) //something like 25 ticks = 20 seconds with the default settings
	else if (iscorgi(M))
		var/mob/living/simple_animal/pet/dog/corgi/C = M
		loc = C
		C.facehugger = src
		C.regenerate_icons()

	GoIdle() //so it doesn't jump the people that tear it off

	spawn(rand(MIN_IMPREGNATION_TIME,MAX_IMPREGNATION_TIME))
		Impregnate(M)

	return 1

/obj/item/clothing/mask/facehugger/proc/Impregnate(mob/living/target)
	if(!target || target.stat == DEAD) //was taken off or something
		return

	if(iscarbon(target))
		var/mob/living/carbon/C = target
		if(C.wear_mask != src)
			return

	if(!sterile)
		//target.contract_disease(new /datum/disease/alien_embryo(0)) //so infection chance is same as virus infection chance
		target.visible_message("<span class='danger'>[src] falls limp after violating [target]'s face!</span>", \
								"<span class='userdanger'>[src] falls limp after violating [target]'s face!</span>")

		Die()
		icon_state = "[initial(icon_state)]_impregnated"

		if(!target.getlimb(/obj/item/organ/limb/robot/chest) && !target.getorgan(/obj/item/organ/internal/body_egg/alien_embryo))
			new /obj/item/organ/internal/body_egg/alien_embryo(target)

		if(iscorgi(target))
			var/mob/living/simple_animal/pet/dog/corgi/C = target
			src.loc = get_turf(C)
			C.facehugger = null
	else
		target.visible_message("<span class='danger'>[src] violates [target]'s face!</span>", \
								"<span class='userdanger'>[src] violates [target]'s face!</span>")

/obj/item/clothing/mask/facehugger/proc/GoActive()
	if(stat == DEAD || stat == CONSCIOUS)
		return

	stat = CONSCIOUS
	icon_state = "[initial(icon_state)]"

/obj/item/clothing/mask/facehugger/proc/GoIdle()
	if(stat == DEAD || stat == UNCONSCIOUS)
		return

	stat = UNCONSCIOUS
	icon_state = "[initial(icon_state)]_inactive"

	spawn(rand(MIN_ACTIVE_TIME,MAX_ACTIVE_TIME))
		GoActive()
	return

/obj/item/clothing/mask/facehugger/proc/Die()
	if(stat == DEAD)
		return

	icon_state = "[initial(icon_state)]_dead"
	item_state = "facehugger_inactive"
	stat = DEAD

	visible_message("<span class='danger'>[src] curls up into a ball!</span>")

/proc/CanHug(mob/living/M)
	if(!istype(M))
		return 0
	if(M.stat == DEAD)
		return 0
	if(M.getorgan(/obj/item/organ/internal/alien/hivenode))
		return 0
	if(iscorgi(M))
		return 1
	var/mob/living/carbon/C = M
	if((ismonkey(C) || ishuman(C)) && isfacehugger(C.wear_mask))
		return 0
	if(ishuman(C) && !(slot_wear_mask in C.dna.species.no_equip))
		return 1
	if(ismonkey(C))
		return 1
	return 0
