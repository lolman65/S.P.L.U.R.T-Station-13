/datum/antagonist/wizard
	name = "Space Wizard"
	roundend_category = "wizards/witches"
	antagpanel_category = "Wizard"
	job_rank = ROLE_WIZARD
	antag_moodlet = /datum/mood_event/focused
	threat = 30
	var/give_objectives = TRUE
	var/strip = TRUE //strip before equipping
	var/allow_rename = TRUE
	var/hud_version = "wizard"
	var/datum/team/wizard/wiz_team //Only created if wizard summons apprentices
	var/move_to_lair = TRUE
	var/outfit_type = /datum/outfit/wizard
	var/wiz_age = WIZARD_AGE_MIN /* Wizards by nature cannot be too young. */
	show_to_ghosts = TRUE

/datum/antagonist/wizard/on_gain()
	register()
	equip_wizard()
	if(give_objectives)
		create_objectives()
	if(move_to_lair)
		send_to_lair()
	var/mob/living/carbon/human/H = owner.current
	H.canloadappearance = TRUE
	H.checkloadappearance()
	. = ..()
	if(allow_rename)
		rename_wizard()

/datum/antagonist/wizard/proc/register()
	SSticker.mode.wizards |= owner

/datum/antagonist/wizard/proc/unregister()
	SSticker.mode.wizards -= src

/datum/antagonist/wizard/create_team(datum/team/wizard/new_team)
	if(!new_team)
		return
	if(!istype(new_team))
		stack_trace("Wrong team type passed to [type] initialization.")
	wiz_team = new_team

/datum/antagonist/wizard/get_team()
	return wiz_team

/datum/team/wizard
	name = "wizard team"
	var/datum/antagonist/wizard/master_wizard

/datum/antagonist/wizard/proc/create_wiz_team()
	wiz_team = new(owner)
	wiz_team.name = "[owner.current.real_name] team"
	wiz_team.master_wizard = src
	update_wiz_icons_added(owner.current)

/datum/antagonist/wizard/proc/send_to_lair()
	if(!owner || !owner.current)
		return
	if(!GLOB.wizardstart.len)
		SSjob.SendToLateJoin(owner.current)
		to_chat(owner, "HOT INSERTION, GO GO GO")
	else
		owner.current.forceMove(pick(GLOB.wizardstart))

/datum/antagonist/wizard/proc/create_objectives()
	var/datum/objective/flavor/wizard/new_objective = new
	new_objective.owner = owner
	new_objective.forge_objective()
	objectives += new_objective

	if (!(locate(/datum/objective/escape) in objectives))
		var/datum/objective/escape/escape_objective = new
		escape_objective.owner = owner
		objectives += escape_objective

/datum/antagonist/wizard/on_removal()
	unregister()
	owner.RemoveAllSpells() // TODO keep track which spells are wizard spells which innate stuff
	return ..()

/datum/antagonist/wizard/proc/equip_wizard()
	if(!owner)
		return
	var/mob/living/carbon/human/H = owner.current
	if(!istype(H))
		return
	if(strip)
		H.delete_equipment()
	//Wizards are human by default. Use the mirror if you want something else.
	H.set_species(/datum/species/human)
	if(H.age < wiz_age)
		H.age = wiz_age
	H.equipOutfit(outfit_type)

/datum/antagonist/wizard/greet()
	to_chat(owner, "<span class='boldannounce'>You are the Space Wizard!</span>")
	to_chat(owner, "<B>The Space Wizards Federation has given you the following tasks:</B>")
	owner.announce_objectives()
	to_chat(owner, "<B>These are merely guidelines! The federation are your masters, but you forge your own path!</B>")
	to_chat(owner, "You will find a list of available spells in your spell book. Choose your magic arsenal carefully.")
	to_chat(owner, "The spellbook is bound to you, and others cannot use it.")
	to_chat(owner, "In your pockets you will find a teleport scroll. Use it as needed.")
	to_chat(owner,"<B>Remember:</B> do not forget to prepare your spells.")

/datum/antagonist/wizard/farewell()
	to_chat(owner, "<span class='userdanger'>You have been brainwashed! You are no longer a wizard!</span>")

/datum/antagonist/wizard/proc/rename_wizard()
	set waitfor = FALSE

	var/wizard_name_first = pick(GLOB.wizard_first)
	var/wizard_name_second = pick(GLOB.wizard_second)
	var/randomname = "[wizard_name_first] [wizard_name_second]"
	var/mob/living/wiz_mob = owner.current
	var/newname = reject_bad_name(stripped_input(wiz_mob, "You are the [name]. Would you like to change your name to something else?", "Name change", randomname, MAX_NAME_LEN))

	if (!newname)
		newname = randomname

	wiz_mob.fully_replace_character_name(wiz_mob.real_name, newname)

/datum/antagonist/wizard/apply_innate_effects(mob/living/mob_override)
	var/mob/living/M = mob_override || owner.current
	update_wiz_icons_added(M, wiz_team ? TRUE : FALSE) //Don't bother showing the icon if you're solo wizard
	M.faction |= ROLE_WIZARD

/datum/antagonist/wizard/remove_innate_effects(mob/living/mob_override)
	var/mob/living/M = mob_override || owner.current
	update_wiz_icons_removed(M)
	M.faction -= ROLE_WIZARD


/datum/antagonist/wizard/get_admin_commands()
	. = ..()
	.["Send to Lair"] = CALLBACK(src,.proc/admin_send_to_lair)

/datum/antagonist/wizard/proc/admin_send_to_lair(mob/admin)
	owner.current.forceMove(pick(GLOB.wizardstart))

/datum/antagonist/wizard/apprentice
	name = "Wizard Apprentice"
	hud_version = "apprentice"
	var/datum/mind/master
	var/school = APPRENTICE_DESTRUCTION
	outfit_type = /datum/outfit/wizard/apprentice
	wiz_age = APPRENTICE_AGE_MIN

/datum/antagonist/wizard/apprentice/greet()
	to_chat(owner, "<B>You are [master.current.real_name]'s apprentice! You are bound by magic contract to follow [master.p_their()] orders and help [master.p_them()] in accomplishing [master.p_their()] goals.")
	owner.announce_objectives()

/datum/antagonist/wizard/apprentice/register()
	SSticker.mode.apprentices |= owner

/datum/antagonist/wizard/apprentice/unregister()
	SSticker.mode.apprentices -= owner

/datum/antagonist/wizard/apprentice/equip_wizard()
	. = ..()
	if(!owner)
		return
	var/mob/living/carbon/human/H = owner.current
	if(!istype(H))
		return
	switch(school)
		if(APPRENTICE_DESTRUCTION)
			owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/projectile/magic_missile(null))
			owner.AddSpell(new /obj/effect/proc_holder/spell/aimed/fireball(null))
			to_chat(owner, "<B>Your service has not gone unrewarded, however. Studying under [master.current.real_name], you have learned powerful, destructive spells. You are able to cast magic missile and fireball.")
		if(APPRENTICE_BLUESPACE)
			owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/turf_teleport/blink(null))
			owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/ethereal_jaunt(null))
			to_chat(owner, "<B>Your service has not gone unrewarded, however. Studying under [master.current.real_name], you have learned reality bending mobility spells. You are able to cast teleport and ethereal jaunt.")
		if(APPRENTICE_HEALING)
			owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/charge(null))
			owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/forcewall(null))
			H.put_in_hands(new /obj/item/gun/magic/staff/healing(H))
			to_chat(owner, "<B>Your service has not gone unrewarded, however. Studying under [master.current.real_name], you have learned livesaving survival spells. You are able to cast charge and forcewall.")
		if(APPRENTICE_ROBELESS)
			owner.AddSpell(new /obj/effect/proc_holder/spell/aoe_turf/knock(null))
			owner.AddSpell(new /obj/effect/proc_holder/spell/pointed/mind_transfer(null))
			to_chat(owner, "<B>Your service has not gone unrewarded, however. Studying under [master.current.real_name], you have learned stealthy, robeless spells. You are able to cast knock and mindswap.")
		if(APPRENTICE_MARTIAL)
			owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/touch/nuclear_fist(null))
			owner.AddSpell(new /obj/effect/proc_holder/spell/self/mantra(null))
			to_chat(owner, "<B>Your service has not gone unrewarded, however. Studying under [master.current.real_name], you have learned to control your Inner Mantra. You are also able to use the Nuclear Fist at will.")

/datum/antagonist/wizard/apprentice/create_objectives()
	var/datum/objective/protect/new_objective = new /datum/objective/protect
	new_objective.owner = owner
	new_objective.target = master
	new_objective.explanation_text = "Protect [master.current.real_name], the wizard."
	objectives += new_objective

//Random event wizard
/datum/antagonist/wizard/apprentice/imposter
	name = "Wizard Imposter"
	allow_rename = FALSE
	move_to_lair = FALSE

/datum/antagonist/wizard/apprentice/imposter/greet()
	to_chat(owner, "<B>You are an imposter! Trick and confuse the crew to misdirect malice from your handsome original!</B>")
	owner.announce_objectives()

/datum/antagonist/wizard/apprentice/imposter/equip_wizard()
	var/mob/living/carbon/human/master_mob = master.current
	var/mob/living/carbon/human/H = owner.current
	if(!istype(master_mob) || !istype(H))
		return
	if(master_mob.ears)
		H.equip_to_slot_or_del(new master_mob.ears.type, SLOT_EARS_LEFT) //skyrat edit
	if(master_mob.w_uniform)
		H.equip_to_slot_or_del(new master_mob.w_uniform.type, SLOT_W_UNIFORM)
	if(master_mob.shoes)
		H.equip_to_slot_or_del(new master_mob.shoes.type, SLOT_SHOES)
	if(master_mob.wear_suit)
		H.equip_to_slot_or_del(new master_mob.wear_suit.type, SLOT_WEAR_SUIT)
	if(master_mob.head)
		H.equip_to_slot_or_del(new master_mob.head.type, SLOT_HEAD)
	if(master_mob.back)
		H.equip_to_slot_or_del(new master_mob.back.type, SLOT_BACK)

	//Operation: Fuck off and scare people
	owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/area_teleport/teleport(null))
	owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/turf_teleport/blink(null))
	owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/ethereal_jaunt(null))

/datum/antagonist/wizard/proc/update_wiz_icons_added(mob/living/wiz,join = TRUE)
	var/datum/atom_hud/antag/wizhud = GLOB.huds[ANTAG_HUD_WIZ]
	wizhud.join_hud(wiz)
	set_antag_hud(wiz, hud_version)

/datum/antagonist/wizard/proc/update_wiz_icons_removed(mob/living/wiz)
	var/datum/atom_hud/antag/wizhud = GLOB.huds[ANTAG_HUD_WIZ]
	wizhud.leave_hud(wiz)
	set_antag_hud(wiz, null)


/datum/antagonist/wizard/academy
	name = "Academy Teacher"
	outfit_type = /datum/outfit/wizard/academy

/datum/antagonist/wizard/academy/equip_wizard()
	. = ..()

	owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/ethereal_jaunt)
	owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/projectile/magic_missile)
	owner.AddSpell(new /obj/effect/proc_holder/spell/aimed/fireball)

	var/mob/living/M = owner.current
	if(!istype(M))
		return

	var/obj/item/implant/exile/Implant = new
	Implant.implant(M)

/datum/antagonist/wizard/academy/create_objectives()
	var/datum/objective/new_objective = new("Protect Wizard Academy from the intruders")
	new_objective.owner = owner
	objectives += new_objective

//Solo wizard report
/datum/antagonist/wizard/roundend_report()
	var/list/parts = list()

	parts += printplayer(owner)

	var/count = 1
	var/wizardwin = 1
	for(var/datum/objective/objective in objectives)
		if(objective.completable)
			var/completion = objective.check_completion()
			if(completion >= 1)
				parts += "<B>Objective #[count]</B>: [objective.explanation_text] <span class='greentext'><B>Success!</B></span>"
			else if(completion <= 0)
				parts += "<B>Objective #[count]</B>: [objective.explanation_text] <span class='redtext'>Fail.</span>"
				wizardwin = FALSE
			else
				parts += "<B>Objective #[count]</B>: [objective.explanation_text] <span class='yellowtext'>[completion*100]%</span>"
		else
			parts += "<B>Objective #[count]</B>: [objective.explanation_text]"
		count++

	if(wizardwin)
		parts += "<span class='greentext'>The wizard was successful!</span>"
	else
		parts += "<span class='redtext'>The wizard has failed!</span>"

	if(owner.spell_list.len>0)
		parts += "<B>[owner.name] used the following spells: </B>"
		var/list/spell_names = list()
		for(var/obj/effect/proc_holder/spell/S in owner.spell_list)
			spell_names += S.name
		parts += spell_names.Join(", ")

	return parts.Join("<br>")

//Wizard with apprentices report
/datum/team/wizard/roundend_report()
	var/list/parts = list()

	parts += "<span class='header'>Wizards/witches of [master_wizard.owner.name] team were:</span>"
	parts += master_wizard.roundend_report()
	parts += " "
	parts += "<span class='header'>[master_wizard.owner.name] apprentices were:</span>"
	parts += printplayerlist(members - master_wizard.owner)

	return "<div class='panel redborder'>[parts.Join("<br>")]</div>"
