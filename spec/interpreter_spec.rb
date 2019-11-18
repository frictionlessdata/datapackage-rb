describe DataPackage::Interpreter do
  describe '#initialize' do
    context 'when CSV is smaller than threshold' do
      it 'sets threshold as CSV length' do
        csv = CSV.read('spec/fixtures/data/names.csv', headers: true)
        interpreter = DataPackage::Interpreter.new(csv)

        expect(interpreter.threshold).to eq(csv.length)
        expect(interpreter.threshold).not_to eq(DataPackage::Interpreter::INFER_THRESHOLD)
      end
    end

    context 'when CSV is larger than threshold' do
      it 'sets threshold as constant' do
        csv = CSV.read('spec/fixtures/data/prices.csv', headers: true)
        interpreter = DataPackage::Interpreter.new(csv)

        expect(interpreter.threshold).to eq(DataPackage::Interpreter::INFER_THRESHOLD)
      end
    end
  end


  describe '#inspect_value' do
    # Which CSV we use doesn't matter here
    let!(:csv) { CSV.read('spec/fixtures/data/names.csv', headers: true) }
    subject { DataPackage::Interpreter.new(csv) }

    context 'dates' do
      it 'interprets %m-%d-%y' do
        expect(subject.inspect_value('01-30-91')).to eq({ 'type' => 'date', 'format' => 'default' })
      end

      it 'interprets %-m-%-d-%Y' do
        expect(subject.inspect_value('1-4-1991')).to eq({ 'type' => 'date', 'format' => 'default' })
      end

      it 'interprets %m/%d/%Y' do
        expect(subject.inspect_value('12/30/1991')).to eq({ 'type' => 'date', 'format' => 'default' })
      end
    end

    context 'datetimes' do
      it 'interprets %Y-%m-%d %H:%M' do
        expect(subject.inspect_value('2019-11-17 12:43:01 -0500')).to eq({ 'type' => 'datetime', 'format' => 'default' })
      end

      it 'interprets iso8601' do
        expect(subject.inspect_value('2019-11-17T13:23:20-05:00')).to eq({ 'type' => 'datetime', 'format' => 'default' })
      end
    end

    context 'times' do
      it 'interprets %H:%M' do
        expect(subject.inspect_value('19:00')).to eq({ 'type' => 'time', 'format' => 'default' })
      end

      it 'interprets %l:%M' do
        expect(subject.inspect_value('1:00')).to eq({ 'type' => 'time', 'format' => 'default' })
      end

      it 'interprets %l%P' do
        expect(subject.inspect_value('1pm')).to eq({ 'type' => 'time', 'format' => 'default' })
      end

      it 'interprets %l%p' do
        expect(subject.inspect_value('12AM')).to eq({ 'type' => 'time', 'format' => 'default' })
      end
    end

    context 'integers' do
      it 'interprets integer as integer' do
        expect(subject.inspect_value('19')).to eq({ 'type' => 'integer', 'format' => 'default' })
      end

      it 'does not interpret numbers and letters as integer' do
        expect(subject.inspect_value('19sdsds')).to eq({ 'type' => 'any', 'format' => 'default' })
      end
    end
  end

  describe '#type_and_format_at' do
    context 'year' do
      it 'returns year as type' do
        csv = CSV.read('spec/fixtures/data/prices.csv', headers: true)
        interpreter = DataPackage::Interpreter.new(csv)
        expect(interpreter.type_and_format_at('year_to_market')).to eq({ 'type' => 'year', 'format' => 'default' })
      end
    end

    context 'date' do
      it 'returns date as type' do
        csv = CSV.read('spec/fixtures/data/prices.csv', headers: true)
        interpreter = DataPackage::Interpreter.new(csv)
        expect(interpreter.type_and_format_at('added_on')).to eq({ 'type' => 'date', 'format' => 'default' })
      end
    end

    context 'time' do
      it 'returns time as type' do
        csv = CSV.read('spec/fixtures/data/prices.csv', headers: true)
        interpreter = DataPackage::Interpreter.new(csv)
        expect(interpreter.type_and_format_at('cutoff_time')).to eq({ 'type' => 'time', 'format' => 'default' })
      end
    end

    context 'datetime' do
      it 'returns datetime as type' do
        csv = CSV.read('spec/fixtures/data/prices.csv', headers: true)
        interpreter = DataPackage::Interpreter.new(csv)
        expect(interpreter.type_and_format_at('updated_at')).to eq({ 'type' => 'datetime', 'format' => 'default' })
      end
    end

    context 'integer' do
      it 'returns integer' do
        csv = CSV.read('spec/fixtures/data/prices.csv', headers: true)
        interpreter = DataPackage::Interpreter.new(csv)
        expect(interpreter.type_and_format_at('price')).to eq({ 'type' => 'integer', 'format' => 'default' })
      end
    end

    context 'string' do
      it 'returns default' do
        csv = CSV.read('spec/fixtures/data/prices.csv', headers: true)
        interpreter = DataPackage::Interpreter.new(csv)
        expect(interpreter.type_and_format_at('id')).to eq({ 'type' => 'any', 'format' => 'default' })
      end
    end
  end
end
