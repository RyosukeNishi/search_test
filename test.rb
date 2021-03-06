class PhraseCreator
  VERB_END_CHARACTERS = %w(う く す つ ぬ ふ む ゆ る ぐ ず づ ぶ)

  ADJECTIVE_PHRASE_END_CHARACTERS = VERB_END_CHARACTERS + ['た', 'の']

  def execute
    Rails.logger.debug "=== Phrase 作成開始 ==="
    @count = 0
  
    titles = Title.all
    titles.each do |title|
      description = title.description

      # 最初の文だけ抽出
      index_of_first_period = description.index("。")
      first_sentence = index_of_first_period.present? ? description.slice(0..(index_of_first_period - 1)) : description

      # 「を」までの部分
      index_of_first_wo_particle = first_sentence.index("を")
      object_phrase_text = index_of_first_wo_particle.present? ? first_sentence.slice(0..index_of_first_wo_particle) : nil

      # 「を」からう段で終わるところ（一番右）までの部分
      index_of_last_verb_end_character = VERB_END_CHARACTERS.map { |character| first_sentence.rindex(character) }.reject(&:nil?).max
      if index_of_last_verb_end_character.present?
        if index_of_first_wo_particle.present?
          verb_phrase_text = first_sentence.slice((index_of_first_wo_particle + 1)..(index_of_last_verb_end_character))
        else
          verb_phrase_text = first_sentence.slice(0..index_of_last_verb_end_character)
        end
      else
        verb_phrase_text = nil
      end

      # う段／「た」／「の」以降の部分
      index_of_last_adjective_phrase_end_character = ADJECTIVE_PHRASE_END_CHARACTERS.map { |character| first_sentence.rindex(character) }.reject(&:nil?).max
      subject_phrase_text = if index_of_last_adjective_phrase_end_character.present?
                              first_sentence.slice((index_of_last_adjective_phrase_end_character + 1)..first_sentence.length)
                            else
                              nil
                            end
      
      create_record ObjectPhrase, object_phrase_text
      create_record VerbPhrase, verb_phrase_text
      create_record SubjectPhrase, subject_phrase_text
    end

    Rails.logger.debug "=== #{@count}件の Phrase を作成しました ==="
  end

  def create_record model, text
    phrase = model.new(text: text)
    if phrase.save
      @count += 1
    end
  end
end