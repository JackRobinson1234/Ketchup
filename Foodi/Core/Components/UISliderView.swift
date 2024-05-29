//
//  UISliderView.swift
//  Foodi
//
//  Created by Jack Robinson on 5/29/24.
//
import SwiftUI
import UIKit

struct UISliderView: UIViewRepresentable {
    @Binding var value: Double
    
    var minValue = 1.0
    var maxValue = 100.0
    var thumbColor: UIColor = .white
    var minTrackColor: UIColor = .blue
    var maxTrackColor: UIColor = .lightGray
    var onEditingChanged: ((Bool) -> Void)? // Closure for editing changes
    
    class Coordinator: NSObject {
        var value: Binding<Double>
        var onEditingChanged: ((Bool) -> Void)?
        
        init(value: Binding<Double>, onEditingChanged: ((Bool) -> Void)?) {
            self.value = value
            self.onEditingChanged = onEditingChanged
        }
        
        @objc func valueChanged(_ sender: UISlider) {
            self.value.wrappedValue = Double(sender.value)
        }
        
        @objc func editingDidBegin(_ sender: UISlider) {
            onEditingChanged?(true)
        }
        
        @objc func editingDidEnd(_ sender: UISlider) {
            onEditingChanged?(false)
        }
    }
    
    func makeCoordinator() -> UISliderView.Coordinator {
        Coordinator(value: $value, onEditingChanged: onEditingChanged)
    }
    
    func makeUIView(context: Context) -> UISlider {
        let slider = UISlider(frame: .zero)
        slider.thumbTintColor = thumbColor
        slider.minimumTrackTintColor = minTrackColor
        slider.maximumTrackTintColor = maxTrackColor
        slider.minimumValue = Float(minValue)
        slider.maximumValue = Float(maxValue)
        slider.value = Float(value)
        
        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.valueChanged(_:)),
            for: .valueChanged
        )
        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.editingDidBegin(_:)),
            for: .touchDown
        )
        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.editingDidEnd(_:)),
            for: [.touchUpInside, .touchUpOutside, .touchCancel]
        )
        
        return slider
    }
    
    func updateUIView(_ uiView: UISlider, context: Context) {
        uiView.value = Float(value)
    }
}
