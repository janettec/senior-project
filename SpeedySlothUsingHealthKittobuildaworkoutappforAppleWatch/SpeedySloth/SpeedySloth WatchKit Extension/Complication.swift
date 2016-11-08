import ClockKit
import HealthKit

class Complication: NSObject, CLKComplicationDataSource {
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Swift.Void) {
        handler([])
    }
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Swift.Void) {
        if complication.family == .modularLarge {
            let template = CLKComplicationTemplateModularLargeTallBody()
            var stepCountString = UserDefaults.standard.string(forKey: "stepCount")
            if (stepCountString == nil) {
                stepCountString = "None"
            }
            template.bodyTextProvider = CLKSimpleTextProvider(text: stepCountString!)
            template.headerTextProvider = CLKSimpleTextProvider(text: "Step Count")
            
            let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(timelineEntry)
        } else {
            handler(nil)
        }
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Swift.Void) {
        handler(CLKComplicationPrivacyBehavior.showOnLockScreen)
    }
    
    func getNextRequestedUpdateDate(handler: @escaping (Date?) -> Swift.Void) {
        handler(Date(timeIntervalSinceNow: 6))
    }
    
    func getPlaceholderTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Swift.Void) {
        if complication.family == .modularLarge {
            let template = CLKComplicationTemplateModularLargeTallBody()
            template.bodyTextProvider = CLKSimpleTextProvider(text: "hello")
            template.headerTextProvider = CLKSimpleTextProvider(text: "there")
            handler(template)
        } else {
            handler(nil)
        }
    }


    

//    func getNextRequestedUpdateDateWithHandler(handler: (NSDate?) -> Void) {
//        handler(nil)
//    }
//    
//    func getPlaceholderTemplateForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTemplate?) -> Void) {
//        handler(nil)
//    }
//    
//    func getPrivacyBehaviorForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationPrivacyBehavior) -> Void) {
//        handler(CLKComplicationPrivacyBehavior.showOnLockScreen)
//    }
//    
//    func getCurrentTimelineEntryForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTimelineEntry?) -> Void) {
//        handler(nil)
//    }
//    
//    func getTimelineEntriesForComplication(complication: CLKComplication, beforeDate date: NSDate, limit: Int, withHandler handler: ([CLKComplicationTimelineEntry]?) -> Void) {
//        handler(nil)
//    }
//    
//    func getTimelineEntriesForComplication(complication: CLKComplication, afterDate date: NSDate, limit: Int, withHandler handler: ([CLKComplicationTimelineEntry]?) -> Void) {
//        handler([])
//    }
//    
//    func getSupportedTimeTravelDirectionsForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTimeTravelDirections) -> Void) {
//        handler([])
//    }
//    
//    func getTimelineStartDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
//        handler(NSDate())
//    }
//    
//    func getTimelineEndDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
//        handler(NSDate())
//    }
}
