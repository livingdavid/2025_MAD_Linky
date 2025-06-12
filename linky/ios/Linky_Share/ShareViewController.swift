import UIKit
import Social
import MobileCoreServices
import UserNotifications

class ShareViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()     // 안내 UI 생성
    handleShare() // 링크 저장 → 알림 발송 → 모달 띄우기 → 종료
  }

  func setupUI() {
    let label = UILabel()
    label.text = "링크 저장됨!\n메인 앱에서 확인하세요"
    label.textAlignment = .center
    label.numberOfLines = 0
    view.addSubview(label)
    label.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
      label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
    ])
  }

  func handleShare() {
    guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
          let provider = item.attachments?.first(where: {
            $0.hasItemConformingToTypeIdentifier("public.url")
          }) else {
      complete()
      return
    }

    provider.loadItem(forTypeIdentifier: "public.url", options: nil) { data, _ in
      guard let urlString = (data as? URL)?.absoluteString else {
        self.complete()
        return
      }

      // ✅ 링크 저장
      let defaults = UserDefaults(suiteName: "group.com.linky")
      defaults?.set(urlString, forKey: "sharedLink")
      defaults?.synchronize()

      // ✅ 로컬 알림 보내기
      self.postNotification(urlString)

      // ✅ 모달 안내창 표시 (메인 스레드에서)
      DispatchQueue.main.async {
        self.displayAutoDismissAlert(
          title: "링크 저장됨!",
          message: "메인 앱에서 확인할 수 있어요 😊",
          duration: 2.0
        )
      }
    }
  }

  func postNotification(_ link: String) {
    let content = UNMutableNotificationContent()
    content.title = "Linky에 링크 저장됨"
    content.body = link
    content.userInfo = ["link": link]
    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
    )
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
  }

  /// 🎯 모달 표시 후 duration 초 뒤 자동 종료
  func displayAutoDismissAlert(title: String, message: String, duration: TimeInterval = 2.0) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    present(alert, animated: true) {
      DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
        alert.dismiss(animated: true) {
          self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
      }
    }
  }

  func complete() {
    extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
  }
}
