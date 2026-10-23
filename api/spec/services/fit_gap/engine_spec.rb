# frozen_string_literal: true

require 'rails_helper'

# Baseline: pins what the engine does correctly today, before the revamp.
RSpec.describe FitGap::Engine do
  let(:vacancy)   { create(:vacancy) }
  let(:portfolio) { create(:portfolio) }
  let(:gemini) do
    FakeGeminiClient.new(response: { 'culture_narrative' => 'Culture text', 'overall_narrative' => 'Overall text' })
  end

  def comparison_for(report, label)
    report.skill_comparisons.find { |c| c['skill_label'] == label }
  end

  it 'classifies each vacancy skill as match, gap or exceed against the candidate level' do
    create(:vacancy_skill, vacancy: vacancy, skill_label: 'Communication', expected_level: 3)
    create(:vacancy_skill, vacancy: vacancy, skill_label: 'SQL',           expected_level: 4)
    create(:vacancy_skill, vacancy: vacancy, skill_label: 'Testing',       expected_level: 2)
    create(:portfolio_skill, portfolio: portfolio, skill_label: 'Communication', ai_level: 3)
    create(:portfolio_skill, portfolio: portfolio, skill_label: 'SQL',           ai_level: 2)
    create(:portfolio_skill, portfolio: portfolio, skill_label: 'Testing',       ai_level: 5)

    report = described_class.new(portfolio: portfolio, vacancy: vacancy, gemini_client: gemini).call

    expect(comparison_for(report, 'Communication')).to include('result' => 'match',  'delta' => 0)
    expect(comparison_for(report, 'SQL')).to           include('result' => 'gap',    'delta' => -2)
    expect(comparison_for(report, 'Testing')).to       include('result' => 'exceed', 'delta' => 3)
  end

  it 'uses the assessor override instead of the AI level' do
    create(:vacancy_skill, vacancy: vacancy, skill_label: 'SQL', expected_level: 4)
    skill = create(:portfolio_skill, portfolio: portfolio, skill_label: 'SQL', ai_level: 2)
    create(:assessor_override, portfolio_skill: skill, override_level: 4)

    report = described_class.new(portfolio: portfolio, vacancy: vacancy, gemini_client: gemini).call

    expect(comparison_for(report, 'SQL')).to include('candidate_level' => 4, 'result' => 'match')
  end

  it 'stores the model narrative when Gemini answers' do
    create(:vacancy_skill, vacancy: vacancy)
    create(:portfolio_skill, portfolio: portfolio)

    report = described_class.new(portfolio: portfolio, vacancy: vacancy, gemini_client: gemini).call

    expect(report.culture_narrative).to eq('Culture text')
    expect(report.overall_narrative).to eq('Overall text')
  end

  it 'regenerating updates the same report row instead of adding one' do
    create(:vacancy_skill, vacancy: vacancy)
    create(:portfolio_skill, portfolio: portfolio)
    engine = described_class.new(portfolio: portfolio, vacancy: vacancy, gemini_client: gemini)

    expect { 2.times { engine.call } }.to change(FitGapReport, :count).by(1)
  end
end
