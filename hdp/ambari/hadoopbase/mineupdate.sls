saltutil.refresh_pillar:
  module.run

mine.update:
  module.run

add_mine_updated_flag:
  grains.present:
    - name: mine:updated
    - value: True