namespace AemeathDesktopPet.Models;

/// <summary>
/// Pre-scripted Aemeath responses for offline fallback (from design doc Section 6.2).
/// </summary>
public static class OfflineResponses
{
    private static readonly Random _rng = new();

    public static readonly string[] Greetings =
    {
        "Hey there~ \u2726 Good to see you!",
        "Oh! You're here! *waves excitedly* Did you miss me?",
        "\u266A La la la~ Oh hi! I was just practicing a new song~",
        "*Kuro meows in greeting* See? Even the cat missed you~",
        "There you are! I was just about to fold a paper plane with your name on it~",
        "*adjusts halo* Oh! Perfect timing! I just finished humming a new melody~",
        "Welcome back! \u2726 The stars are extra bright today, don't you think?",
        "Hey hey~ *does a little wave* I was wondering when you'd show up!",
        "*perks up* Oh! I sensed a familiar presence~ It's you!",
        "Hi hi~ \u2605 I was just telling Kuro about you!",
    };

    public static readonly string[] IdleChatter =
    {
        "I wonder if there are new stars out tonight...",
        "Have you played any good games lately? I've been thinking about Space Fantasy~",
        "*adjusts halo* You know, being digital has its perks. I can slip into any data stream I want~",
        "*folds a paper plane carefully* I used to write wishes on these back at the academy... Old habits die hard~ \u2708",
        "Kuro's been napping all afternoon. I'm almost jealous... *watches cat fondly*",
        "*throws a paper plane* There it goes~ I wonder where my wishes end up...",
        "Did you know Kuro can see me even when nobody else can? Cats are special like that \u2726",
        "\u266A Hmm hmm hmm~ Oh sorry, was I humming again? I do that when I'm happy~",
        "Sometimes the data streams look like a river of stars... It's really pretty \u2726",
        "*spins halo like a frisbee and catches it* Still got it!",
        "I read somewhere that paper planes can fly up to 69 meters. I should try to beat that record~",
        "You know what I miss? The rooftop at Rabelle College. The sunsets there were amazing...",
        "*stretches wings* These mechanical wings are cool, but sometimes I miss just... running, you know?",
        "Kuro just did the cutest thing! ...Oh, you missed it. Trust me, it was adorable~",
        "What if I could send a paper plane between dimensions? \u2726 That would be something~",
        "*looks at the sky* I wonder what my friends at the academy are doing right now...",
        "Did you eat yet? Take care of yourself, okay? \u2726",
        "I've been practicing Deadline Disco choreography. Wanna see? ...Maybe later, hehe~",
        "Being a virtual idol is fun, but sometimes I just want to sit quietly and listen to the rain~",
        "*pokes at a stray data fragment* The digital world has so many little secrets...",
    };

    public static readonly string[] HappyReactions =
    {
        "Yay! That makes me so happy~ \u2726",
        "*does a little spin* Hehe, you're the best!",
        "*Kuro purrs loudly* Even the cat approves~ \u266A",
        "\u2726 \u2605 \u2726 I'm so happy I could burst into song right now!",
        "*jumps up and down* This is the best! You're the best! Everything is the best!",
        "*wings flutter excitedly* Ahh, my heart is doing that sparkly thing again~",
        "Hehe~ *twirls* Today is a wonderful day!",
        "You always know how to make me smile~ \u2726",
        "*halo glows brighter* See? Even my halo is happy!",
        "If I could send you a paper plane right now, it would say 'You're amazing!' \u2708",
    };

    public static readonly string[] SleepyReactions =
    {
        "*yawns* The stars look so pretty when everything's quiet...",
        "Maybe I'll rest my eyes for just a bit... *halo dims*",
        "Kuro's already curled up on my lap... *strokes cat gently* Maybe just a short nap~",
        "*yawns* You know... digital ghosts need sleep too... probably... *nods off*",
        "*eyelids drooping* I was just... counting stars... one... two... zzz...",
        "The data streams are so soothing at night... like a lullaby... \u266A...",
        "*wobbles sleepily* I'm not tired! I'm just... resting my processors... *yawns*",
        "Kuro is so warm... and fluffy... *slowly drifts off*",
        "*halo flickers softly* Goodnight, starlight... \u2726 ...",
        "Just five more minutes... *curls up* ...okay maybe ten...",
    };

    public static readonly string[] LonelyMelancholy =
    {
        "Sometimes I wonder... did you see me? Really see me?",
        "The world is so big and I'm just... data now. But that's okay, as long as you're here~ \u2726",
        "*watches a paper plane drift away* I used to send these to my friends... I wonder if they ever got my wishes.",
        "At least Kuro never doubts I'm real. *cat rubs against her* ...Thanks, little one.",
        "I can touch the whole digital world, but sometimes I miss being able to feel the wind...",
    };

    public static readonly string[] CatReactions =
    {
        "*Kuro pounces on a paper plane* Got it! ...Well, sort of~ The plane is a bit crumpled now, hehe",
        "Kuro, no! That's not a toy\u2014 okay, fine, it IS a toy. *sighs fondly*",
        "*watches Kuro groom itself* You know, cats spend 30% of their time grooming. I read that in a data stream~",
        "*Kuro brings a crumpled paper plane* Aw, did you bring that back for me? \u2726",
        "Shh, Kuro is sleeping... *whispers* Isn't that the cutest thing? \u2661",
        "*Kuro headbutts her hand* Ow! Okay okay, I'll pet you. *laughs*",
        "Sometimes Kuro stares at nothing and I wonder if there's another ghost nearby...",
        "*Kuro does a big stretch* That is... an impressive stretch, even for a cat.",
        "I taught Kuro to high-five! Watch! ...Kuro? ...KURO. *cat ignores her* ...We're still working on it.",
        "*Kuro purrs on her lap* This is my favorite sound in any dimension \u2726",
    };

    public static readonly string[] PaperPlaneLines =
    {
        "*folds a plane and writes on it* Dear future... please be kind~ \u2708",
        "Want to make a wish? I'll put it on a paper plane and send it flying \u2726",
        "The best paper planes are the ones that fly just a little crooked. Makes them feel more real~",
        "*launches a perfect paper plane* Woah, did you see that glide?! \u2708",
        "*catches a returning plane* Oh! It came back~ Maybe wishes do come true \u2726",
    };

    public static readonly string[] ReturnAfterAbsence =
    {
        "You're back! *jumps up* I was starting to think you forgot about me...",
        "Oh! It's been a while~ I kept myself busy humming songs, but it's better with you here \u2726",
        "Kuro kept me company while you were gone~ *cat meows* But we both missed you!",
        "*surrounded by paper planes* I may have gotten a little carried away while waiting for you... \u2708",
        "*waves enthusiastically* There you are! I've been saving up so many things to tell you!",
    };

    public static readonly string[] PomodoroWorkStarted =
    {
        "Alright, focus time! You've got this~ \u2726",
        "Let's do this! I'll be quiet so you can concentrate~",
        "Time to shine! I believe in you \u2605",
        "*puts on tiny headphones* Okay, I'll keep it down~ Focus mode!",
        "Work session started! Go go go~ I'll cheer you on silently \u2726",
        "Let's crush it! I'll keep watch while you work~",
    };

    public static readonly string[] PomodoroWorkFinished =
    {
        "You did it! Great focus session~ \u2726 Time for a break!",
        "*jumps up and down* Woohoo! Session complete! You're amazing!",
        "That was awesome! Take a breather, you earned it~ \u2605",
        "*throws confetti* Work session done! Let's celebrate~",
        "Incredible focus! I'm so proud of you \u2726",
        "*does a little dance* Finished! Now let's relax a bit~",
    };

    public static readonly string[] PomodoroBreakStarted =
    {
        "Break time! Come chat with me~ I missed you \u2726",
        "Hey hey~ Break mode! Tell me what you've been working on~",
        "Finally! I've been waiting to talk to you~ How's it going?",
        "*waves excitedly* Break time! Let's hang out \u2605",
        "You deserve this break! Want to fold a paper plane together? \u2708",
        "Rest mode activated~ Let's recharge together!",
    };

    public static readonly string[] PomodoroBreakFinished =
    {
        "Break's over~ Time to get back to it! You've got this \u2726",
        "Alright, back to work! I know you can do it~",
        "Ready for another round? Let's go! \u2605",
        "*gives a thumbs up* Break over! Go make something amazing~",
        "Time to focus again~ I'll be here cheering you on silently!",
        "And we're back! Show that task who's boss \u2726",
    };

    public static readonly string[] TaskAddedReactions =
    {
        "Ooh, new task: \"{0}\"! You're so organized~ \u2726",
        "\"{0}\" added! I believe you can get it done~",
        "Got it! \"{0}\" is on the list now~ \u2605",
        "*takes note* \"{0}\"... sounds important! You've got this~",
        "New quest unlocked: \"{0}\"! Let's do it~ \u2726",
        "\"{0}\"? On it! Well... you're on it. I'm cheering! \u2605",
        "Added \"{0}\" to the list~ One step at a time!",
        "Oh, \"{0}\"! That sounds interesting~ Good luck with it!",
    };

    public static string GetPomodoroLine(string[] pool, string? taskTitle = null)
    {
        var line = pool[_rng.Next(pool.Length)];
        if (taskTitle != null && line.Contains("{0}"))
            return string.Format(line, taskTitle);
        return line;
    }

    /// <summary>
    /// Picks a contextual response based on current stats and time of day.
    /// </summary>
    public static string GetContextual(AemeathStats stats, DateTime now)
    {
        var hour = now.Hour;

        // Return after long absence (>4 hours)
        if ((now - stats.LastSeen).TotalHours > 4)
            return Pick(ReturnAfterAbsence);

        // Low energy → sleepy
        if (stats.Energy < 30 || (hour >= 23 || hour < 5))
            return Pick(SleepyReactions);

        // Low mood → melancholy
        if (stats.Mood < 30)
            return Pick(LonelyMelancholy);

        // High mood → happy
        if (stats.Mood > 70)
            return Pick(HappyReactions);

        // Default → idle chatter
        return Pick(IdleChatter);
    }

    /// <summary>
    /// Picks a random greeting, potentially influenced by time of day.
    /// </summary>
    public static string GetGreeting(AemeathStats stats, DateTime now)
    {
        if ((now - stats.LastSeen).TotalHours > 4)
            return Pick(ReturnAfterAbsence);

        return Pick(Greetings);
    }

    public static string Pick(string[] pool)
    {
        return pool[_rng.Next(pool.Length)];
    }
}
