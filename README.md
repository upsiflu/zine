# README


This is Zine, a little  experimental app for creating and infinite collages of editable hypertext blocks.

[Check out the current design considerations](https://github.com/upsiflu/zine/wiki)

**For experiments with a sample frontend that uses a firestore database in lieu of the planned p2p backend, check out [zine-store](https://github.com/upsiflu/zine-store).**

### Scope and Target Groups

Part of the research about "Shells", the MVP's intended application is to host a living archive of the first [Shell Congress](shellcongress.com). Building on that, we envision to continue our research on Shells in tandem with the further development of the Zine codebase.

Our foremost concern is thus analysis, theory and documentation. We are sharing each step of our activity with the wider community and aim to connect with fellow projects of similar vein. Our target groups comprise researchers, curators, activists, communities and artists that have a strong need to escape from the Silos and the grammars of exploitation, but that are not so techy as to set up their own servers and connect to the fediverse.


### Motivation

Valki, part of the Shell Congress team, re-writes (or re-assembles) colonial history through their zines. Perhaps you are familiar with the works of Hanna Höch who similarly used collage to de-normalize images and evoke deviant meanings.

The Zine app aims to bring the practice of subversive collage to the internet, a space currently dominated by for-profit platforms.

### Theory

Current web platforms adhere to a (trans)humanist ideology where 'the user' is a creature bound to self-optimization and competition. Social edges are the currency; the ad industry feeds on artificial desires. The 'Human' is a fig leaf - both inessential (even limiting, concerning the advance of technology) and concealing. Below that is both the boundless animal/plant/mineral, i.e. a user whose desires are physical, and an economy where social edges are more than models. 

We want to find the self-imposed limitations that the humanist model generates, and reduce its influence on our imagination-- both in terms of UX, in terms of user-generated content, and in terms of social edges.

### Research

In 2018, we have coducted interviews with users of a class of apps that implement a 2D collage model: researchcatalogue.net and hotglue.me

#### Potential use cases:

- Artist portfolios that are not individual. Compare: instagram, where an AI curates a stream of subscriptions.
- 'Living' Archives that continue to grow and change and interact with their audience.
- Collage-shaped essays, artworks that live as if they were research in public domain. Compare: Are.na

### Technology

In the spirit of our goal, we keep our project:

- free, open source and public domain
- accessible (via existing a11y technologies)
- compatible: our content format is pure Hypertext (Html excluding any javascript).

Html already gives us all multimedia capabilities that are available in the present. And yet, it is so ubiquitous that any software - office apps, but also siloed apps such as facebook - produce and consume it happily. Every user can mix and match Html though copy and paste, and every hardware platform offers a variety of accessibility affordances for these operations.

# Implementation

1. Create a simple hypertext editor
2. Create a mosaic in which hypertext tiles can be arranged and linked-to
3. Implement a diff algorithm to encode operations on hypertext-DOM and mosaic arrangement
4. Implement a simple server to propagate diffs across browsers

Viola, our MVP ;-)

### Potential avenues from there

The following ideas will need to evolve from testing the MVP

- Distributed server (each client takes somee hosting duty, so that we don't need a central server any more)
- Transclusions (selections from one zine appear in another)
- Image editing: background removal, color correction, perspective manipulation
- Avatars
- Localized live sound sharing (like in [gather.town](https://gather.town/app/5Wp6ebk3fOGv9Uuo/SHELL), but without the video)
- Time Travel
- Stories, curated paths through the tiles
- Signature (to get in touch with specific people)


-----------------------




# Implementation

## Toolbar

There is a single toolbar on screen, with automatically assigned shortcuts. Any focused item can add a sub-toolbar. Duplicate toolbar actions from different items merge and will simultaneously affect both items. 

## Keyboard Input

`Enter`: Do the 'default' action. For example, when a tile is focused, Enter makes it editable, restoring its previous cursor. During editing, Enter would add paragraphs.
