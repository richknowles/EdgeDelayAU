// EdgeDelayViewController.swift
// UI for The Edge-style delay/reverb effect

import CoreAudioKit
import UIKit

public class EdgeDelayViewController: AUViewController {
    private var audioUnit: EdgeDelayAudioUnit?
    private var parameterObserverToken: AUParameterObserverToken?

    // UI Controls
    private var delayTimeSlider: UISlider!
    private var delayFeedbackSlider: UISlider!
    private var delayMixSlider: UISlider!
    private var reverbSizeSlider: UISlider!
    private var reverbMixSlider: UISlider!
    private var shimmerSlider: UISlider!
    private var shimmerPitchSlider: UISlider!
    private var dryWetSlider: UISlider!

    private var labels: [UILabel] = []
    private var valueLabels: [UILabel] = []

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)

        setupUI()

        guard let audioUnit = audioUnit else { return }

        // Observe parameter changes
        if let paramTree = audioUnit.parameterTree {
            parameterObserverToken = paramTree.token(byAddingParameterObserver: { [weak self] address, value in
                DispatchQueue.main.async {
                    self?.updateControlValue(address: address, value: value)
                }
            })
        }
    }

    deinit {
        if let token = parameterObserverToken, let audioUnit = audioUnit {
            audioUnit.parameterTree?.removeParameterObserver(token)
        }
    }

    private func setupUI() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "The Edge Delay"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        stackView.addArrangedSubview(titleLabel)

        // Delay Section
        let delaySection = createSection(title: "DELAY")
        delayTimeSlider = createSlider(spec: EdgeDelayParameterSpecs.delayTime, in: delaySection)
        delayFeedbackSlider = createSlider(spec: EdgeDelayParameterSpecs.delayFeedback, in: delaySection)
        delayMixSlider = createSlider(spec: EdgeDelayParameterSpecs.delayMix, in: delaySection)
        stackView.addArrangedSubview(delaySection)

        // Reverb Section
        let reverbSection = createSection(title: "REVERB")
        reverbSizeSlider = createSlider(spec: EdgeDelayParameterSpecs.reverbSize, in: reverbSection)
        reverbMixSlider = createSlider(spec: EdgeDelayParameterSpecs.reverbMix, in: reverbSection)
        stackView.addArrangedSubview(reverbSection)

        // Shimmer Section
        let shimmerSection = createSection(title: "SHIMMER MAGIC")
        shimmerSlider = createSlider(spec: EdgeDelayParameterSpecs.shimmerAmount, in: shimmerSection)
        shimmerPitchSlider = createSlider(spec: EdgeDelayParameterSpecs.shimmerPitch, in: shimmerSection)
        stackView.addArrangedSubview(shimmerSection)

        // Master Section
        let masterSection = createSection(title: "MASTER")
        dryWetSlider = createSlider(spec: EdgeDelayParameterSpecs.dryWet, in: masterSection)
        stackView.addArrangedSubview(masterSection)

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    private func createSection(title: String) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        container.layer.cornerRadius = 8

        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(label)
        container.addSubview(stackView)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),

            stackView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
        ])

        return container
    }

    @discardableResult
    private func createSlider(spec: ParameterSpec, in container: UIView) -> UISlider {
        guard let stackView = container.subviews.compactMap({ $0 as? UIStackView }).first else {
            fatalError("Container must have a stack view")
        }

        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center

        let nameLabel = UILabel()
        nameLabel.text = spec.name
        nameLabel.font = UIFont.systemFont(ofSize: 14)
        nameLabel.textColor = .lightGray
        nameLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true

        let slider = UISlider()
        slider.minimumValue = spec.minValue
        slider.maximumValue = spec.maxValue
        slider.value = spec.defaultValue
        slider.tag = Int(spec.address)
        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        slider.minimumTrackTintColor = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0)

        let valueLabel = UILabel()
        valueLabel.text = formatValue(spec.defaultValue, unit: spec.unit)
        valueLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        valueLabel.textColor = .white
        valueLabel.textAlignment = .right
        valueLabel.widthAnchor.constraint(equalToConstant: 60).isActive = true
        valueLabel.tag = Int(spec.address)

        row.addArrangedSubview(nameLabel)
        row.addArrangedSubview(slider)
        row.addArrangedSubview(valueLabel)

        stackView.addArrangedSubview(row)

        labels.append(nameLabel)
        valueLabels.append(valueLabel)

        return slider
    }

    @objc private func sliderChanged(_ slider: UISlider) {
        guard let audioUnit = audioUnit,
              let param = audioUnit.parameterTree?.parameter(withAddress: AUParameterAddress(slider.tag)) else {
            return
        }

        param.value = slider.value
    }

    private func updateControlValue(address: AUParameterAddress, value: AUValue) {
        // Update slider
        if let slider = view.viewWithTag(Int(address)) as? UISlider {
            slider.value = value
        }

        // Update value label
        if let valueLabel = valueLabels.first(where: { $0.tag == Int(address) }) {
            let spec = EdgeDelayParameterSpecs.all.first { $0.address == address }
            valueLabel.text = formatValue(value, unit: spec?.unit ?? .generic)
        }
    }

    private func formatValue(_ value: Float, unit: AudioUnitParameterUnit) -> String {
        switch unit {
        case .milliseconds:
            return String(format: "%.0f ms", value)
        case .relativeSemiTones:
            return String(format: "%.0f st", value)
        default:
            return String(format: "%.2f", value)
        }
    }
}

// MARK: - AUAudioUnitFactory
extension EdgeDelayViewController: AUAudioUnitFactory {
    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        let audioUnit = try EdgeDelayAudioUnit(componentDescription: componentDescription)
        self.audioUnit = audioUnit
        return audioUnit
    }
}
