<game>

  <div class="left col-md-3">
    <info_box resources={this.resources}/>
  </div>
  <div class="center col-md-6">
    <chat/>
    <action_box />
  </div>

  <div class="right col-md-3">
    <info_right_box/>
  </div>



  <script>

    this.areas = {'main':new Deck(), 'temp':new Deck(),'game':new Deck(), 'hand':new Deck(), 'discard':new Deck()}
    this.resources = {'pj':new Resource(), 'ally':new Resource(), 'victim':new Resource(),
                      'pj_feature':new Resource(), 'pj_contact':new Resource(), 'pj_object':new Resource(),
                      'enigma_clue':new Resource(), 'enigma_where':new Resource(), 'enigma_what':new Resource()
                    }

    this.enigma_resources_count = 3


    this.findGetParameter = function(parameterName) {
      var result = null
      var   tmp = []
      location.search.substr(1).split("&").forEach(function (item) {
            tmp = item.split("=");
            if (tmp[0] === parameterName) result = decodeURIComponent(tmp[1]);
          });
      return result;
    }

    this.deckname = this.findGetParameter('deck') || 'default_deck'

    this.areas.main = new Deck(decks[this.deckname])

    if (this.deckname == 'todas') {
      var todas = []
      for (var name in decks) {
        for (var i in decks[name]) {
          todas.push(decks[name][i])
        }
      }
      this.areas.main = new Deck(todas)
    }

    this.loadArea = function(area, cards) {
      this.areas[area].load(cards)
    }

    this.unloadArea = function(area, cards) {
      this.areas[area].unload(cards)
    }

    this.setResource = function(resourceName, card) {
      this.resources[resourceName].card = card
    }

    this.moveCardsFromTo = function(from, to, cards) {
      this.unloadArea(from, cards)
      this.loadArea(to, cards)
    }

    this.moveFromAreaToResource = function(area, resource, card) {
      this.unloadArea(area, card)
      this.setResource(resource, card)
    }

    this.phases = [ {number:0, description:'Initial phase'},
                    {number:1, description:'first phase'},
                    {number:2, description:'second phase'},
                    {number:3, description:'third phase'},
                    {number:4, description:'fourth phase'}
    ]
    this.currentAction = ''

    this.currentPhase = 0

    this.nextPhase = function(text, user) {
      this.currentPhase++
      if (this.currentPhase > this.phases.length) {
        this.currentPhase = 0
      }
    }

    this.characterProgress = 0
    this.characterConditions = 0
    this.moveActions = [new Action('action_goal', 'Resolver'), new Action('action_attack', 'Investigar'), new Action('action_wait', 'Esperar'),
                        new Action('action_sacrifice', 'Sacrificar recurso'), new Action('action_reverse', 'Revertir situación')]

    this.respondToEnigma = [new Action('action_pj_respond', 'Responder con mejor carta'),
                           new Action('action_pj_sacrifice', 'Sacrificar recurso de mejor valor'),
                           new Action('action_pj_luck', 'Sacar carta del mazo'),
                         new Action('action_pj_condition', 'Asumir condicion')]


    this.cardsToActions = function(cards, actionName) {
      var actions = []
      for (var i=0; i< cards.length; i++) {
        actions.push({name:actionName, label:cards[i].number+' '+cards[i].text, data:{card:cards[i]}})
      }
      return actions
    }

    this.chooseCharacter = function(data, resourceName, nextActionName, characterLabel, nextCharacterLabel ) {
      var card = data['card']
      this.moveFromAreaToResource('temp', resourceName ,card)
      var actions = this.cardsToActions(this.areas.temp.cards, nextActionName)
      riot.actionStore.trigger('add_chat', 'El '+characterLabel+' es: '+card.text)
      if (nextCharacterLabel && nextCharacterLabel != '') {
        riot.actionStore.trigger('add_chat', 'Elige '+nextCharacterLabel)
        this.nextActions(actions)
      }
    }

    this.nextActions = function(actions) {
      riot.actionStore.trigger('add_actions', actions)
    }

    this.selectCharactersResources = function() {
      self.areas.main.shuffle()

      self.moveFromAreaToResource('main', 'pj_feature' , self.areas.main.topCard())
      self.moveFromAreaToResource('main', 'pj_contact' , self.areas.main.findByType('Personaje').topCard())
      self.moveFromAreaToResource('main', 'pj_object' ,  self.areas.main.findByType('Objeto').topCard())
    }

    this.selectEnigmaQuestions = function() {
      self.areas.main.shuffle()

      self.moveFromAreaToResource('main', 'enigma_clue' ,  self.areas.main.topCard())
      self.moveFromAreaToResource('main', 'enigma_where' , self.areas.main.findByType('Lugar').topCard())
      self.moveFromAreaToResource('main', 'enigma_what' ,  self.areas.main.findByType('Detalle').topCard())
    }

    this.selectDestinyCards = function() {
      var cards = self.areas.main.topCards(5)
      self.moveCardsFromTo('main', 'hand', cards)
    }

    this.check_end_game_contitions = function() {
      if (self.characterConditions == 3) {
        riot.actionStore.trigger('add_chat', 'Tienes 3 condiciones, has sido derrotado. Utiliza las ultimas cartas como inspiración de como termina tu personaje.')
      } else if (self.characterProgress >= 3 && self.enigma_resources_count == 0) {
        riot.actionStore.trigger('add_chat', 'Resolviste el enigma y atrapaste al autor. Has vencido. Describe el final.')
      } else if (self.characterProgress >= 3 && self.enigma_resources_count > 0) {
        riot.actionStore.trigger('add_chat', 'Resolviste el enigma pero no has atrapado al autor. Te falta investigar algun detalle.')
      } else if (self.enigma_resources_count == 0) {
        riot.actionStore.trigger('add_chat', 'Tienes todas las pistas necesarias pero debes resolver las 3 preguntas del enigma.')
      }
    }

    this.resetState = function() {
      this.nextActions(this.moveActions)
      self.currentAction = ''
      this.selectedCard = {}
      this.enigmaCard = {}
      this.selectedEnigmaResource = ''
      riot.actionStore.trigger('update_hand_info', this.areas.hand.cards)
      riot.actionStore.trigger('update_resource_info', this.resources)
    }

    this.reorganization = function() {
      var discard_cards = self.areas.discard.cards
      if (self.areas.main.cards.length < discard_cards.length) {
        self.moveCardsFromTo('discard', 'main', discard_cards)
        self.areas.main.shuffle
        riot.actionStore.trigger('add_chat', 'Reorganización.')
      }
    }

    this.selectedCard = {}
    this.enigmaCard = {}
    this.selectedEnigmaResource = ''
    this.selectedPjResource = ''
    var self = this

    riot.actionStore.on('run_action', function(actionName, data) {
      self.doAction(actionName, data)
    })

    riot.actionStore.on('enigma_resource_selected', function(resourceName) {
      if (self.currentAction == 'action_attack') {
        self.selectedEnigmaResource = resourceName
        riot.actionStore.trigger('add_chat', 'Recurso del enigma seleccionada, ahora selecciona una de tus cartas. El enigma respondera con otra carta, si tu carta es menor tendras exito')
      }
    })

    riot.actionStore.on('pj_resource_selected', function(resourceName) {
      if (self.currentAction == 'action_sacrifice') {
        self.selectedPjResource = resourceName
        self.doMove('sacrifice')
      }

      if (self.currentAction == 'action_pj_sacrifice') {
        self.selectedPjResource = resourceName
        self.doMove('pj_sacrifice')
      }
    })

    riot.actionStore.on('card_selected', function(card) {
      self.selectedCard = card
      switch(self.currentAction) {
        case 'action_goal':
          self.doMove('goal')
          break
        case 'action_pj_respond':
          self.doMove('pj_respond')
          break
        case 'action_attack':
          if (self.selectedEnigmaResource) {
            self.doMove('attack')
          } else {
            riot.actionStore.trigger('add_chat', 'Selecciona la pregunta del enigma primero y luego la carta.')
          }
          break
        case 'action_reverse':
          self.doMove('reverse')
        default:
          console.log('default selectedcard')
      }
    })

    this.doAction = function(actionName, data) {
      switch(actionName) {
        case 'initGame':
         var mainDeck = this.areas.main
         mainDeck.shuffle()
         var newDeck = mainDeck.findByType('Personaje')
         var cards = newDeck.topCards(8) || newDeck
         this.moveCardsFromTo('main', 'temp', cards)
         var actions = this.cardsToActions(cards, 'choosePj')
         riot.actionStore.trigger('add_chat', 'Elige al protagonista')
         this.nextActions(actions)

         break
        case 'choosePj':
          this.chooseCharacter(data, 'pj', 'chooseAlly', 'protagonista', 'aliado' )
          riot.actionStore.trigger('update_resource_info', this.resources)
          break
        case 'chooseAlly':
          this.chooseCharacter(data, 'ally', 'chooseVictim', 'aliado', 'victima' )
          riot.actionStore.trigger('update_resource_info', this.resources)
          break
        case 'chooseVictim':
          this.chooseCharacter(data, 'victim', 'choosePjFeature', 'victima')
          riot.actionStore.trigger('update_resource_info', this.resources)
          riot.actionStore.trigger('add_chat', 'A continuacion se generan las relaciones y caracteristicas de los personajes')
          this.doAction('generateResources')
          break
        case 'generateResources':
          this.selectCharactersResources()
          this.selectEnigmaQuestions()
          riot.actionStore.trigger('update_resource_info', this.resources)
          riot.actionStore.trigger('add_chat', 'Elige nombres para los personajes y escribe una breve historia sobre el enigma utilizando el Como, Donde, la Pista y la Victima.')
          this.nextActions([{name:'chooseDestinyCards', label:'Tomar cartas de destino.'}])
        case 'chooseDestinyCards':
          riot.actionStore.trigger('add_chat', 'Ahora tienes 5 cartas de destino. Estaran en tu mano y las podras usar a lo largo del juego.')
          this.selectDestinyCards()
          riot.actionStore.trigger('update_hand_info', this.areas.hand.cards)
          this.nextActions(this.moveActions)
          break
        case 'action_goal':
          riot.actionStore.trigger('add_chat', 'Elige la carta de tu mano, y escribe como resuelves una de las interrogantes (Quien, Como, Por que) del enigma con ella. Deja la historia abierta porque el enigma puede superarte.')
          self.currentAction = 'action_goal'
          this.nextActions([])
          break
        case 'action_attack':
          riot.actionStore.trigger('add_chat', 'Elige uno de los recursos del enigma que quieres investigar y luego una carta de tu mano (debe ser menor para tener exito).')
          // riot.actionStore.trigger('add_chat', 'Investigaste en detalle ese recurso por lo que no esta mas presente en la aventura. Escribe que descubres y como afecta la aventura.')
          self.currentAction = 'action_attack'
          this.nextActions([])
          break
        case 'action_wait':
          riot.actionStore.trigger('add_chat', 'Esperas. Obtienes una nueva carta en tu mano pero el enigma te da problemas.')
          self.currentAction = 'action_wait'
          self.doMove('wait')
          break
        case 'action_sacrifice':
          riot.actionStore.trigger('add_chat', 'Elige el recurso que quieres sacrificar y escribe como se pierde para siempre. Gracias a esto obtendras dos cartas.')
          self.currentAction = 'action_sacrifice'
          this.nextActions([])
          break
        case 'action_reverse':
          if (self.characterConditions > 0) {
            riot.actionStore.trigger('add_chat', 'Describe como intentas revertir una condición inspirandote en la carta que selecciones.')
            self.currentAction = 'action_reverse'
            this.nextActions([])
          } else {
            riot.actionStore.trigger('add_chat', 'No tienes condiciones que revertir.')
          }

          break
        case 'action_enigma_turn':
          riot.actionStore.trigger('add_chat', 'Turno del Enigma')
          var enigmaCard = self.areas.main.topCard()
          self.enigmaCard = enigmaCard
          self.moveCardsFromTo('main', 'discard', enigmaCard)
          riot.actionStore.trigger('add_chat', 'La carta del enigma es '+enigmaCard.fullText())
          riot.actionStore.trigger('add_chat', 'Escribe como intenta perjudicarte inspirandote en la carta')
          this.nextActions(self.respondToEnigma)
          break
        case 'action_pj_respond':
          riot.actionStore.trigger('add_chat', 'Elige la carta de tu mano que sea mejor que la del enigma.')
          self.currentAction = 'action_pj_respond'
          this.nextActions([])
          break
        case 'action_pj_sacrifice':
          riot.actionStore.trigger('add_chat', 'Elige el recurso que quieres sacrificar.')
          self.currentAction = 'action_pj_sacrifice'
          break
        case 'action_pj_luck':
          self.currentAction = 'action_pj_luck'
          self.doMove('pj_luck')
          break
        case 'action_pj_condition':
          self.currentAction = 'action_pj_condition'
          self.doMove('pj_condition')
          break

        default:
          console.log('default action')
      }
    }

    this.doMove = function(moveName, data) {
      this.reorganization()
      switch(moveName) {
        case 'goal':
          var myCard = self.selectedCard
          var enigmaCard = self.areas.main.topCard()
          self.enigmaCard = enigmaCard
          riot.actionStore.trigger('add_chat', 'La carta del enigma es '+enigmaCard.fullText())
          riot.actionStore.trigger('add_chat', 'Tu carta es '+myCard.fullText())

          self.moveCardsFromTo('hand', 'discard', myCard)
          self.moveCardsFromTo('main', 'discard', enigmaCard)
          self.resetState()

          if (myCard.number < enigmaCard.number) {
            self.characterProgress++
            riot.actionStore.trigger('add_chat', 'Superado, tu progreso aumenta a '+self.characterProgress)
            riot.actionStore.trigger('add_chat', 'Logras resolver una de las interrogantes, escribe la respuesta utilizando las cartas como inspiración.')
            riot.actionStore.trigger('update_characterProgress', self.characterProgress)
            self.check_end_game_contitions()
          } else {
            riot.actionStore.trigger('add_chat', 'No logras superarlo, tienes un problema en la investigacion. Como lo resuelves?')
            this.nextActions(self.respondToEnigma)
          }

          break
        case 'attack':
          var myCard = self.selectedCard
          var EnigmaResource = self.selectedEnigmaResource
          var enigmaCard = self.resources[EnigmaResource].card
          if (myCard.number < enigmaCard.number) {
            riot.actionStore.trigger('add_chat', 'Triunfas. Tu carta: '+myCard.text+' supera a la carta del enigma: '+enigmaCard.text)
            riot.actionStore.trigger('add_chat', 'Ya investigaste todo sobre este recurso. Obtienes 2 cartas de destino')
            self.resources[EnigmaResource].unset()
            self.enigma_resources_count--
            // get 2 free cards
            self.moveCardsFromTo('main', 'hand', self.areas.main.topCard())
            self.moveCardsFromTo('main', 'hand', self.areas.main.topCard())

            self.check_end_game_contitions()
          } else {
            riot.actionStore.trigger('add_chat', 'Pierdes. Tu carta: '+myCard.text+' pierde ante la carta del enigma: '+enigmaCard.text)
            this.nextActions(self.respondToEnigma)
          }
          self.moveCardsFromTo('hand', 'discard', myCard)
          break
        case 'wait':
          var newCard = self.areas.main.topCard()
          self.moveCardsFromTo('main', 'hand', newCard)
          self.doAction('action_enigma_turn')
          break
        case 'sacrifice':
          var resourceName = self.selectedPjResource
          var cards = self.areas.main.topCards(3)
          self.moveCardsFromTo('main', 'hand', cards)
          riot.actionStore.trigger('add_chat', 'Sacrificas tu recurso: '+self.resources[resourceName].card.text)
          riot.actionStore.trigger('add_chat', 'A cambio btienes 3 cartas de destino pero tu recurso se pierde para siempre, explica como.')
          self.resources[resourceName].unset()
          self.resetState()
          self.doAction('action_enigma_turn')
          break
        case 'reverse':
          var myCard = self.selectedCard
          var enigmaCard = self.areas.main.topCard()
          riot.actionStore.trigger('add_chat', 'Tu carta seleccionada es: '+myCard.fullText())
          riot.actionStore.trigger('add_chat', 'La carta del enigma es: '+enigmaCard.fullText())

          if (myCard.number < enigmaCard.number) {
            riot.actionStore.trigger('add_chat', 'Logras revertir la condición')
            self.characterConditions--
            riot.actionStore.trigger('update_characterConditions', self.characterConditions)
          } else {
            riot.actionStore.trigger('add_chat', 'No logras revertir la condición')
            self.nextActions(self.respondToEnigma)
          }
          self.moveCardsFromTo('hand', 'discard', myCard)
          self.moveCardsFromTo('main', 'discard', enigmaCard)
          self.resetState()
          break
        case 'pj_respond':
          var myCard = self.selectedCard
          var enigmaCard = self.enigmaCard
          self.moveCardsFromTo('hand', 'discard', myCard)
          self.moveCardsFromTo('main', 'discard', enigmaCard)
          self.resetState()

          if (myCard.number < enigmaCard.number) {
            riot.actionStore.trigger('add_chat', 'Superas el obstaculo, describe como ')
          } else {
            riot.actionStore.trigger('add_chat', 'No superado')
            this.nextActions(self.respondToEnigma)
          }

          break
        case 'pj_sacrifice':
          var resourceName = self.selectedPjResource
          if (self.resources[resourceName].card.number < self.enigmaCard.number ) {
            riot.actionStore.trigger('add_chat', 'Superas el obstaculo pero pierdes para siempre tu recurso: '+self.resources[resourceName].card.text)
            self.resources[resourceName].unset()
            self.resetState()
          } else {
            riot.actionStore.trigger('add_chat', 'No lo superas y pierdes para siempre tu recurso: '+self.resources[resourceName].card.text)
            self.resources[resourceName].unset()
            this.nextActions(self.respondToEnigma)
          }
          break
        case 'pj_luck':
          var myCard = self.areas.main.topCard()
          self.selectedCard = myCard
          riot.actionStore.trigger('add_chat', 'Sacas la carta: '+myCard.fullText())

          if (myCard.number < self.enigmaCard.number ) {
            riot.actionStore.trigger('add_chat', 'Superas el obstaculo con un poco de suerte')
          } else {
            riot.actionStore.trigger('add_chat', 'No lo superas.')
            self.doMove('pj_condition')
          }
          self.resetState()

          break
        case 'pj_condition':
          self.characterConditions++
          riot.actionStore.trigger('update_characterConditions', self.characterConditions)
          riot.actionStore.trigger('add_chat', 'Agrega una nueva condicion, tus condiciones aumentan a: '+self.characterConditions)
          self.resetState()
          self.check_end_game_contitions()
          break
        default:
          console.log('default move')
          break
      }
    }
  </script>
</game>
