#lang forge
open "pdpa-simple.frg"

test expect {
    /*
    TO DO:
    * Add tests to figure out the greatest lower bound for number of states for tests / runs
    */


    --- Tests of specification / model ----------------------------------------------------------
    wellformedVacuity: { wellformed } is sat
    tracesVacuity: { traces } is sat

    ------- Notification mechanics

    EnablingPredForNotifyingPDPCIsSat: {
        traces
        some {s: State | enabledOrgPotentiallyNotifiesPDPC[s]}
    } for {next is linear} is sat

    PossibleOrgNotifiesPDPC: {
        traces 
        some {s: State | nOrgNotifiesPDPC in s.notifyStatus[Org]}
    }  for 4 State for {next is linear} is sat 

    PossibleOrgNotNotifyPDPC: {
        traces 
        no {s: State | nOrgNotifiesPDPC in s.notifyStatus[Org]}
    }  for 4 State for {next is linear} is sat 

    PossibleOrgNotifiesAffected: {
        traces 
        some {s: State | nNotifyAffected in s.notifyStatus[Org]}
    }  for {next is linear} is sat 

    OrgNotifiesAffectedOnlyAtMostOnce: {
        traces implies #{s: State | nNotifyAffected in s.notifyStatus[Org]} <= 1
    } for 3 State for {next is linear} is theorem
    -- TO DO: check with higher number of states once we fix the stutter transitions

    PossibleOrgNotifyAffectedBeforeNotifyingPDPC: {
        traces
        some disj s1, s2: State | 
            { 
                s2 in s1.^next
                nNotifyAffected in s1.notifyStatus[Org]
                nOrgNotifiesPDPC in s2.notifyStatus[Org]
            }
    } for {next is linear} is sat

    PossibleOrgNotifyAffectedBeforeNOTNotifyingPDPC: {
        traces
        some disj s1, s2: State | 
            { 
                s2 in s1.^next
                nNotifyAffected in s1.notifyStatus[Org]
                nOrgNOTnotifyPDPC in s2.notifyStatus[Org]
            }
    } for {next is linear} is sat

    PossibleOrgNOTNotifyAffectedBeforeNotifyingPDPC: {
        traces
        some disj s1, s2: State | 
            { 
                s2 in s1.^next
                nOrgNOTnotifyAffected in s1.notifyStatus[Org]
                nOrgNotifiesPDPC in s2.notifyStatus[Org]
            }
    } for {next is linear} is sat

    PossibleOrgNOTNotifyAffectedBeforeNOTNotifyingPDPC: {
        traces
        some disj s1, s2: State | 
            { 
                s2 in s1.^next
                nOrgNOTnotifyAffected in s1.notifyStatus[Org]
                nOrgNOTnotifyPDPC in s2.notifyStatus[Org]
            }
    } for {next is linear} is sat


    PDPCWillNotMakeBothNotifications: {
        traces implies #{s: State | nNotifyAffected in s.notifyStatus[PDPC] or nPDPCSaysDoNotNotifyAffected in s.notifyStatus[PDPC] } <= 1      
    } for 3 State for {next is linear} is theorem
    -- TO DO: check with higher number of states once we fix the stutter transitions

    PossibleForPDPCToSayNotify: {
        traces
        some {s: State | nNotifyAffected in s.notifyStatus[PDPC]}
    } for 4 State for {next is linear} is sat
   
    PossibleForPDPCToImposeGagOrder: {
        traces
        some {s: State | nPDPCSaysDoNotNotifyAffected in s.notifyStatus[PDPC]}
    } for 4 State for {next is linear} is sat

    PDPCWillNotRespondToOrgAtSameTimeThatOrgConsidersNotifyingPDPC: {
        traces  
        some s: State | PDPCRespondsToOrgIfOrgHadNotified[s, s.next] and orgPotentiallyNotifiesPDPC[s, s.next]
    } for {next is linear} is unsat

    OrgNotifyingPDPCIsDueToMovePred: {
        traces
        some s: State |
            { 
                nOrgNotifiesPDPC in (s.next).notifyStatus[Org] or nOrgNOTnotifyPDPC in (s.next).notifyStatus[Org]
                not orgPotentiallyNotifiesPDPC[s, s.next]
            }
    } for 4 State for {next is linear} is unsat

    OrgNotifyingAffectedIsDueToMovePred: {
        traces
        some s: State |
            { 
                nNotifyAffected in (s.next).notifyStatus[Org] or nOrgNOTnotifyAffected in (s.next).notifyStatus[Org]

                not orgPotentiallyNotifiesAffected[s, s.next]
            }
    } for 4 State for {next is linear} is unsat

    OrgNotifsToAffectedOnlyOnOneStateMax: {
        traces implies 
            #{s: State | 
                nNotifyAffected in s.notifyStatus[Org] or 
                nOrgNOTnotifyAffected in s.notifyStatus[Org]} <= 1
    } for 5 State for {next is linear} is theorem

    // clean up occurs exactly once
    CleanupOrgNotifiesPDPExactlyOnce: {
        traces implies 
            #{s: State | 
                some s.next and cleanupOrgNotifiesPDPC[s, s.next]} <= 1
    } for 5 State for {next is linear} is theorem

    OrgNotifsToPDPCOnlyOnOneStateMax: {
        traces implies 
            #{s: State | 
                nOrgNotifiesPDPC in s.notifyStatus[Org] or 
                nOrgNOTnotifyPDPC in s.notifyStatus[Org]} <= 1
    } for 5 State for {next is linear} is theorem

    PDPCNotifsOnlyOnOneStateMax: {
        traces implies 
            #{s: State | 
                nNotifyAffected in s.notifyStatus[PDPC] or 
                nPDPCSaysDoNotNotifyAffected in s.notifyStatus[PDPC]} <= 1
    } for 5 State for {next is linear} is theorem
 
    // Suppose PDPC tells Org not to notify affected. It's still possible for Org to subsequently notify affected.
    OrgCanStillNotifyEvenAfterPDPCSaysNotTo: {
        traces
        some s: State |
            { 
                nPDPCSaysDoNotNotifyAffected in s.notifyStatus[PDPC]
                some s.next
                nNotifyAffected in (s.next).notifyStatus[Org] 
            }
    } for 4 State for {next is linear} is sat

    // It's possible for Org to notify PDPC and notify affected, and for PDPC to __subsequently__ say NOT to notify
    PDPCCanSayNotToNotifyEvenAfterOrgHasNotifiedAffected: {
        traces
        // s2 can be s1
        some s1, s2: State |
            { 
                some preStatesWithPriorNotifn[Org, nOrgNotifiesPDPC, s1.(~next)] 
                // org notifies pdpc before s1

                nNotifyAffected in s1.notifyStatus[Org] 
                // org notifies affected on s1

                s2 in (s1  + s1.^next)                             
                nPDPCSaysDoNotNotifyAffected in s2.notifyStatus[PDPC]
                // pdpc says not to notify on either s1 or some state after
            }
    } for 4 State for {next is linear} is sat


    PDPCWillNotRespondToOrgBeforeOrgConsidersNotifyingPDPC: {
        traces  
        some disj s1, s2: State | 
            {
                s2 in s1.^next
                nNotifyAffected in s1.notifyStatus[PDPC] or nPDPCSaysDoNotNotifyAffected in s1.notifyStatus[PDPC]
                
                nOrgNotifiesPDPC in s2.notifyStatus[Org] or nOrgNOTnotifyPDPC in s2.notifyStatus[Org]
                // this obviously assumes that the org move pred will make one of these two moves
            }
    } for 3 State for {next is linear} is unsat

    PDPCWillAlwaysRespondToOrgIfOrgNotifiesIt:  {
        traces  
        some s1: State | 
            {
                s1 = stNDBreach or s1 = stNDBreach.next 
                nOrgNotifiesPDPC in s1.notifyStatus[Org] 

                
                no {s2: State | s2 in s1.^next and (nNotifyAffected in s2.notifyStatus[PDPC] or nPDPCSaysDoNotNotifyAffected in s2.notifyStatus[PDPC])}
            } 
    } for 4 State for {next is linear} is unsat

    ------- Obligation mechanics

    /*TO DO: 

    */

    --- tests of the legislation / 'system'
}


