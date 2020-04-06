<info_box >

  <div class="panel panel-info hand_box">
    <div class="panel-heading"><h4 class="panel-title">Mano</h4></div>
    <div class="panel-body">
      <div class="hand btn btn-info btn-xs" each={card in cards} onclick={selectCard}>
        {card.fullText()}
      </div>
    </div>
  </div>

  <div class="panel panel-info enigma_resources_box">
    <div class="panel-heading"><h4 class="panel-title">Enigma </p></h4></div>
    <div class="panel-body">
      <ul class="list-unstyled">
        <li riot-tag="list-group-item" header="Que Paso" text={this.resources['enigma_what'].card.fullText()} data-resource="enigma_what" onclick={selectEnigmaResource}></li>
        <li riot-tag="list-group-item" header="Donde" text={this.resources['enigma_where'].card.fullText()}  data-resource="enigma_where" onclick={selectEnigmaResource}></li>
        <li riot-tag="list-group-item" header="Pista" text={this.resources['enigma_clue'].card.fullText()}  data-resource="enigma_clue" onclick={selectEnigmaResource}></li>
      </ul>
    </div>
  </div>

  <div class="panel panel-info my_resources_box">
    <div class="panel-heading"><h4 class="panel-title">Recursos Protagonista</h4></div>
    <div class="panel-body">
      <ul class="list-group">
        <li riot-tag="list-group-item" header="Caracteristica del protagonista" text={this.resources['pj_feature'].card.fullText()} data-resource="pj_feature" onclick={selectPjResource}></li>
        <li riot-tag="list-group-item" header="Contacto/testigo" text={this.resources['pj_contact'].card.fullText()} data-resource="pj_contact" onclick={selectPjResource}></li>
        <li riot-tag="list-group-item" header="Recurso especial" text={this.resources['pj_object'].card.fullText()} data-resource="pj_object" onclick={selectPjResource}></li>
      </ul>
    </div>
  </div>
  <script>

    this.resources = opts.resources || []
    this.cards = opts.cards || []
    this.selectedCard = {}
    this.selectedVictimResource = ''

    this.selectCard = function(event) {
      this.selectedCard = event.item.card
      riot.actionStore.trigger('card_selected', this.selectedCard)
    }

    this.selectEnigmaResource = function(event) {
      var resourceName = event.currentTarget.dataset.resource
      if (this.resources[resourceName].card) {
        riot.actionStore.trigger('enigma_resource_selected', resourceName)
      }
    }

    this.selectPjResource = function(event) {
      var resourceName = event.currentTarget.dataset.resource
      if (this.resources[resourceName].card) {
        riot.actionStore.trigger('pj_resource_selected', resourceName)
      }
    }

    var self = this

    this.on('mount', function() {
    })

    riot.actionStore.on('update_resource_info', function(resources) {
      self.resources = resources
      self.update()
    })

    riot.actionStore.on('update_hand_info', function(cards) {
      self.cards = cards
      self.update()
    })

  </script>
</info_box>
